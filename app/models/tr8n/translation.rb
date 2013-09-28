#--
# Copyright (c) 2013 Michael Berkovich, tr8nhub.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
#
#-- Tr8n::Translation Schema Information
#
# Table name: tr8n_translations
#
#  id                    INTEGER       not null, primary key
#  translation_key_id    integer       not null
#  language_id           integer       not null
#  translator_id         integer       not null
#  label                 text          not null
#  rank                  integer       default = 0
#  approved_by_id        integer(8)    
#  rules                 text          
#  synced_at             datetime      
#  created_at            datetime      not null
#  updated_at            datetime      not null
#  context               text          
#
# Indexes
#
#  tr8n_trn_c       (created_at) 
#  tr8n_trn_tktl    (translation_key_id, translator_id, language_id) 
#  tr8n_trn_t       (translator_id) 
#
#++

class Tr8n::Translation < ActiveRecord::Base
  self.table_name = :tr8n_translations
  attr_accessible :translation_key_id, :language_id, :translator_id, :label, :rank, :approved_by_id, :rules, :context, :synced_at
  attr_accessible :language, :translator, :translation_key

  after_create    :distribute_notification
  after_save      :update_cache
  after_destroy   :update_cache

  belongs_to :language,         :class_name => "Tr8n::Language"
  belongs_to :translation_key,  :class_name => "Tr8n::TranslationKey"
  belongs_to :translator,       :class_name => "Tr8n::Translator"

  has_many :translation_key_sources,  :class_name => "Tr8n::TranslationKeySource",  :through => :translation_key
  has_many :translation_sources,      :class_name => "Tr8n::TranslationSource",     :through => :translation_key_sources
  
  has_many  :translation_votes, :class_name => "Tr8n::TranslationVote", :dependent => :destroy
  
  serialize :rules
  serialize :context
    
  alias :key :translation_key
  alias :votes :translation_votes

  # TODO: move this to config file
  VIOLATION_INDICATOR = -10

  #{
  #    "count" => {"number":"one"},
  #    "user" => {"gender":"male", "value":"vowels"}
  #    "date" => {"date":"future"}
  #}
  def matches_rules?(token_values)
    return true unless context # doesn't have any rules

    context.each do |token_name, rules|
      token_object = Tr8n::Tokens::Base.token_object(token_values, token_name)
      return false if token_object.nil?

      rules.each do |context_key, rule_key|
        next if rule_key == 'other'
        context = language.context_by_keyword(context_key)
        rule = context.find_matching_rule(token_object)
        return false unless rule and rule.keyword == rule_key
      end
    end

    true
  end

  def context_description
    return nil unless context

    description = []
    context.each do |token_name, rules|
      token_description = []
      rules.each do |context_key, rule_key|
        context = Tr8n::LanguageContext.by_keyword_and_language(context_key, language)
        rule = context.rule_by_keyword(rule_key)
        next unless rule
        desc = rule.sanitize_description(token_name)
        token_description << desc if desc
      end
      description << token_description.join(" and ")
    end

    description.join("; ").html_safe
  end

  # used by the permutation generator
  def matches_context?(generated_context)
    context == generated_context
  end

  def vote!(translator, score)
    score = score.to_i
    vote = Tr8n::TranslationVote.find_or_create(self, translator)

    vote.update_attributes(:vote => score.to_i)
    
    Tr8n::Notification.distribute(vote)

    update_rank!
    
    # update the translation key timestamp
    key.touch

    self.translator.update_rank!(language) if self.translator
    
    # add the dashboard to the watch list
    self.translator.update_attributes(:reported => true) if score < VIOLATION_INDICATOR
    
    translator.voted_on_translation!(self)
    translator.update_metrics!(language)
    translation_key.update_metrics!(language)
  end
  
  def update_rank!
    new_rank = 0
    Tr8n::TranslationVote.where(:translation_id => self.id).each do |tv|
      Tr8n::Logger.debug("#{tv.inspect}")
      next unless tv.translator
      Tr8n::Logger.debug("voting power #{tv.translator.voting_power} #{tv.vote}")
      new_rank += (tv.translator.voting_power * tv.vote)
    end

    Tr8n::Logger.debug("rank #{new_rank}")

    update_attributes(:rank => new_rank)
  end
  
  def reset_votes!(translator)
    Tr8n::TranslationVote.delete_all(["translation_id = ?", self.id])
    vote!(translator, 1)
  end
  
  # TODO: move this stuff to decorators
  def rank_style(rank)
    Tr8n::Config.default_rank_styles.each do |range, color|
      return color if range.include?(rank)
    end
    "color:grey"
  end
  
  # TODO: move this stuff to decorators
  def rank_label
    return "<span style='color:grey'>0</span>" if rank.blank?
    
    prefix = (rank > 0) ? "+" : ""
    "<span style='#{rank_style(rank)}'>#{prefix}#{rank}</span>".html_safe 
  end

  # TODO: verify if it is necessary
  def self.default_translation(translation_key, language, translator)
    trans = where("translation_key_id = ? and language_id = ? and translator_id = ? and context is null", translation_key.id, language.id, translator.id).order("rank desc").first
    return trans if trans
    label = translation_key.default_translation if translation_key.is_a?(Tr8n::RelationshipKey)
    new(:translation_key => translation_key, :language => language, :translator => translator, :label => label || translation_key.sanitized_label)
  end

  def blank?
    label.blank?
  end

  def uniq?
    # for now, treat all translations as uniq
    return true
    
    trns = self.class.where("translation_key_id = ? and language_id = ? and label = ?", translation_key.id, language.id, label)
    trns = trns.where("id <> ?", self.id) if self.id
    trns.count == 0
  end
  
  def clean?
    language.clean_sentence?(label)
  end
  
  def can_be_edited_by?(editor)
    return false if translation_key.locked?
    translator == editor
  end

  def can_be_deleted_by?(editor)
    return false if translation_key.locked?
    return true if editor.manager?
    
    translator == editor
  end

  def save_with_log!(translator)
    if self.id
      translator.updated_translation!(self) if changed?
    else  
      translator.added_translation!(self)
    end
    
    save
  end
  
  def destroy_with_log!(translator)
    translator.deleted_translation!(self)
    
    destroy
  end

  def distribute_notification
    Tr8n::Notification.distribute(self)
  end

  def update_cache
    return if Tr8n::RequestContext.block_options[:skip_cache]
    language.translations_changed! if language
    translation_key.translations_changed!(language) if translation_key
  end

  ###############################################################
  ## API
  ###############################################################
  def to_api_hash(opts = {})
    hash = {"locale" => language.locale, "label" => label, "context" => context}
    return hash if opts[:comparible]

    hash.merge("rank" => rank)
  end

  ###############################################################
  ## Synchronization Methods
  ###############################################################
  # generates the hash without rule ids, but with full definitions
  #def mark_as_synced!
  #  update_attributes(:synced_at => Time.now + 2.seconds)
  #end
  #
  #def rules_sync_hash(opts = {})
  #  @rules_sync_hash ||= (rules || []).collect{|rule| rule[:rule].to_api_hash(opts.merge(:token => rule[:token]))}
  #end
  #
  #def rules_api_hash(opts = {})
  #  return nil if rules.nil? or rules.empty?
  #  rulz = {}
  #  rules.each do |rule|
  #    rulz[rule[:token]] ||= []
  #    rulz[rule[:token]] << {
  #      :type => rule[:rule].class.dependency,
  #      :key => rule[:rule].keyword
  #    }
  #  end
  #  rulz
  #end
  #
  ## create translation from API hash for a specific key
  #def self.create_from_sync_hash(tkey, dashboard, thash, opts = {})
  #  return if thash["label"].blank?  # don't add empty translations
  #
  #  lang = Tr8n::Language.by_locale(thash["locale"])
  #  return unless lang  # don't add translations for an unsupported settings
  #
  #  # generate rules for the translation
  #  rules = []
  #  if thash["rules"] and thash["rules"].any?
  #    thash["rules"].each do |rhash|
  #      rule = Tr8n::LanguageRule.create_from_sync_hash(lang, dashboard, rhash, opts)
  #      return unless rule # if the rule has not been created, we should not even add the translation
  #      rules << {:token => rhash["token"], :rule_id => rule.id}
  #    end
  #  end
  #  rules = nil if rules.empty?
  #
  #  tkey.add_translation(thash["label"], rules, lang, dashboard)
  #end
    
  ###############################################################
  ## Search Methods
  ###############################################################
  def self.filter_status_options
    [["all translations", "all"], 
     ["accepted", "accepted"],
     ["pending", "pending"],
     ["rejected", "rejected"]].collect{|option| [option.first.trl("Translation filter status option"), option.last]}
  end
  
  def self.filter_submitter_options
    [["by anyone", "anyone"],
     ["by me", "me"]].collect{|option| [option.first.trl("Translation filter submitter option"), option.last]}
  end
  
  def self.filter_date_options
    [["on any date", "any"],
     ["today", "today"], 
     ["yesterday", "yesterday"], 
     ["in the last week", "last_week"]].collect{|option| [option.first.trl("Translation filter date option"), option.last]}
  end
  
  def self.filter_order_by_options
    [["date", "date"], 
     ["rank", "rank"]].collect{|option| [option.first.trl("Translation filter order by option"), option.last]}
  end
  

  def self.filter_group_by_options
    [["not grouped", "nothing"],
     ["grouped by translator", "translator"],
     ["grouped by context rule", "context"],
     ["grouped by rank", "rank"],
     ["grouped by date", "date"]].collect{|option| [option.first.trl("Translation filter group by option"), option.last]}
  end
  
  def self.for_params(params, language = Tr8n::RequestContext.current_language)
    if language.nil?
      results = self.where("language_id is not null")
    else
      results = self.where("language_id = ?", language.id)
    end

    # only translations from the selected application
    if params[:application]
      results = results.joins(:translation_sources).where("tr8n_translation_sources.application_id = ?", params[:application].id)
    end
    
    # ensure that only allowed translations are visible
    allowed_level = Tr8n::RequestContext.current_user_is_translator? ? Tr8n::RequestContext.current_translator.level : 0
    results = results.joins(:translation_key).where("tr8n_translation_keys.level <= ?", allowed_level) 
    
    if params[:only_phrases]  
      results = results.where("tr8n_translation_keys.type is null or tr8n_translation_keys.type = ? or tr8n_translation_keys.type = ?", 'Tr8n::TranslationKey', 'TranslationKey')
    end

    unless params[:search].blank?
      results = results.where("tr8n_translations.label like ?", "%#{params[:search]}%")
    end

    if params[:with_status] == "accepted"
      results = results.where("tr8n_translations.rank >= ?", params[:application].threshold)
    elsif params[:with_status] == "pending"
      results = results.where("tr8n_translations.rank >= 0 and tr8n_translations.rank < ?", params[:application].threshold)
    elsif params[:with_status] == "rejected"
      results = results.where("tr8n_translations.rank < 0")
    end

    unless params[:submitted_by].blank?
      if params[:submitted_by] == "me"
        results = results.where("tr8n_translations.translator_id = ?", Tr8n::RequestContext.current_user_is_translator? ? Tr8n::RequestContext.current_translator.id : 0)
      else
        results = results.where("tr8n_translations.translator_id = ?", params[:submitted_by].id)
      end
    end

    if params[:submitted_on] == "today"
      date = Date.today
      results = results.where("tr8n_translations.created_at >= ? and tr8n_translations.created_at < ?", date, date + 1.day)
    elsif params[:submitted_on] == "yesterday"
      date = Date.today - 1.days
      results = results.where("tr8n_translations.created_at >= ? and tr8n_translations.created_at < ?", date, date + 1.day)
    elsif params[:submitted_on] == "last_week"
      date = Date.today - 7.days
      results = results.where("tr8n_translations.created_at >= ? and tr8n_translations.created_at < ?", date, Date.today)
    end    
    results.uniq
  end 
    
end
