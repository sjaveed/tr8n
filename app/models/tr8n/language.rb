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
#-- Tr8n::Language Schema Information
#
# Table name: tr8n_languages
#
#  id                      integer                        not null, primary key
#  locale                  character varying(255)         not null
#  english_name            character varying(255)         not null
#  native_name             character varying(255)         
#  threshold               integer                        default = 1
#  enabled                 boolean                        
#  right_to_left           boolean                        
#  completeness            integer                        
#  fallback_language_id    integer                        
#  curse_words             text                           
#  featured_index          integer                        default = 0
#  google_key              character varying(255)         
#  facebook_key            character varying(255)         
#  myheritage_key          character varying(255)         
#  created_at              timestamp without time zone    not null
#  updated_at              timestamp without time zone    not null
#
# Indexes
#
#  tr8n_ll    (locale) 
#
#++

class Tr8n::Language < ActiveRecord::Base
  self.table_name = :tr8n_languages

  include Tr8n::Modules::Logger

  attr_accessible :locale, :english_name, :native_name, :enabled, :right_to_left, :completeness, :fallback_language_id, :curse_words, :featured_index
  attr_accessible :google_key, :facebook_key, :myheritage_key
  attr_accessible :fallback_language

  after_save      :update_cache
  after_destroy   :update_cache

  belongs_to :fallback_language,    :class_name => 'Tr8n::Language',            :foreign_key => :fallback_language_id

  has_many :language_contexts,      :class_name => 'Tr8n::LanguageContext',     :dependent => :destroy
  has_many :language_cases,         :class_name => 'Tr8n::LanguageCase',        :dependent => :destroy

  has_many :language_users,         :class_name => 'Tr8n::LanguageUser',        :dependent => :destroy
  has_many :translations,           :class_name => 'Tr8n::Translation',         :dependent => :destroy
  has_many :translation_key_locks,  :class_name => 'Tr8n::TranslationKeyLock',  :dependent => :destroy
  has_many :language_metrics,       :class_name => 'Tr8n::Metrics::Language'

  has_many :country_languages,      :class_name => 'Tr8n::CountryLanguage',     :order => "position asc", :dependent => :destroy
  has_many :countries,              :class_name => 'Tr8n::Country',             :through => :country_languages, :order => "tr8n_country_languages.position asc"

  ###############################################################
  ## CACHE METHODS
  ###############################################################
  def self.cache_key(locale)
    "language_[#{locale}]"
  end

  def flag
    @flag ||= Tr8n::Media::LanguageFlag.where(:owner_type => self.class.name, :owner_id => self.id).first
  end

  def flag_url
    flag ? flag.url(:original, :full => true) : "#{Tr8n::Config.base_url}/assets/tr8n/tr8n_flag.png"
  end

  def featured?(app)
    al = Tr8n::ApplicationLanguage.where(:application_id=>app.id, :language_id => id).first
    return false unless al
    not al.featured_index.nil?
  end

  def manager?(translator)
    return true if translator.admin?
    translator_language = Tr8n::TranslatorLanguage.where(:language_id => self.id, :translator_id => translator.id).first
    return false unless translator_language
    translator_language.manager?
  end

  def cache_key
    self.class.cache_key(locale)
  end
  
  def language_contexts_cache_key
    "contexts_[#{locale}]"
  end

  def language_cases_cache_key
    "cases_[#{locale}]"
  end

  def self.featured_languages_cache_key
    "featured_languages"
  end

  def self.enabled_languages_cache_key
    "enabled_languages"
  end

  def update_cache
    Tr8n::Cache.delete(cache_key)
    Tr8n::Cache.delete(language_contexts_cache_key)
    Tr8n::Cache.delete(language_cases_cache_key)
    Tr8n::Cache.delete(self.class.featured_languages_cache_key)
    Tr8n::Cache.delete(self.class.enabled_languages_cache_key)
  end

  def toggle_feature(keyword, flag)
    Tr8n::Feature.toggle(self, keyword, flag)
  end

  def feature_enabled?(keyword)
    Tr8n::Feature.enabled?(self, keyword)
  end

  ###############################################################
  ## FINDER METHODS
  ###############################################################

  def self.by_locale(locale)
    return nil if locale.nil?
    return locale if locale.is_a?(Tr8n::Language)
    Tr8n::Cache.fetch(cache_key(locale)) do
      find_by_locale(locale)
    end
  end

  def self.find_or_create(lcl, english_name)
    find_by_locale(lcl) || create(:locale => lcl, :english_name => english_name) 
  end

  def contexts
    @contexts ||= begin
      Tr8n::Cache.fetch(language_contexts_cache_key) do
        language_contexts
      end
    end
  end

  def reset!
    @contexts = nil
    @cases = nil
    @bad_words = nil
    reload
  end

  def context_by_keyword(keyword, opts = {})
    contexts.detect{|ctx| ctx.keyword == keyword}
  end

  def context_by_token_name(token_name, opts = {})
    contexts.each do |ctx|
      return ctx if ctx.applies_to_token?(token_name)
    end
    nil
  end

  def cases
    @cases ||= begin
      Tr8n::Cache.fetch(language_cases_cache_key) do
        language_cases
      end
    end
  end

  def current?
    self.locale == Tr8n::RequestContext.current_language.locale
  end
  
  def default?
    self.locale == Tr8n::Config.default_locale
  end
  
  def cases?
    not cases.empty?
  end

  def case_keyword_maps
    @case_keyword_maps ||= begin
      hash = {} 
      cases.each do |lcase| 
        hash[lcase.keyword] = lcase
      end
      hash
    end
  end
  
  def suggestible?
    not google_key.blank?
  end
  
  def case_for(case_keyword)
    case_keyword_maps[case_keyword]
  end
  
  def valid_case?(case_keyword)
    case_for(case_keyword) != nil
  end

  def name
    return native_name unless native_name.blank?
    english_name
  end

  def full_name
    return english_name if english_name == native_name or native_name.blank?
    "#{english_name} - #{native_name}"
  end

  def self.options
    enabled_languages.collect{|lang| [lang.english_name, lang.id.to_s]}
  end
  
  def self.locale_options
    enabled_languages.collect{|lang| [lang.english_name, lang.locale]}
  end

  def self.filter_options
    find(:all, :order => "english_name asc").collect{|lang| [lang.english_name, lang.id.to_s]}
  end
  
  def enable!
    self.enabled = true
    save
  end

  def disable!
    self.enabled = false
    save
  end
  
  def disabled?
    not enabled?
  end
  
  def dir
    right_to_left? ? "rtl" : "ltr"
  end
  
  def align(dest)
    return dest unless right_to_left?
    dest.to_s == 'left' ? 'right' : 'left'
  end
  
  def self.enabled_languages
    Tr8n::Cache.fetch(enabled_languages_cache_key) do 
      where("enabled = ?", true).order("english_name asc").all
    end
  end

  def self.featured_languages
    Tr8n::Cache.fetch(featured_languages_cache_key) do 
      where("enabled = ? and featured_index is not null and featured_index > 0", true).order("featured_index desc").all
    end
  end

  def self.translate(label, desc = "", tokens = {}, options = {})
    Tr8n::RequestContext.current_language.translate(label, desc, tokens, options)
  end

  def translate(label, desc = "", tokens = {}, options = {})
    raise Tr8n::Exception.new("The label #{label} is being translated twice") if label.tr8n_translated?

    unless Tr8n::Config.enabled?
      return Tr8n::TranslationKey.substitute_tokens(self, label, tokens, options).tr8n_translated.html_safe
    end

    translation_key = Tr8n::TranslationKey.find_or_create(label, desc, options)
    translation_key.translate(self, tokens.merge(:viewing_user => Tr8n::RequestContext.current_user), options).tr8n_translated.html_safe
  rescue Exception => ex
    Tr8n::Logger.error(ex.message)
    Tr8n::Logger.error(ex.backtrace)

    #return label if options[:skip_decorations]
    "<span style='background:red; padding:5px; color:white'>#{label}</span>".html_safe
  end
  alias :tr :translate

  def trl(label, desc = "", tokens = {}, options = {})
    tr(label, desc, tokens, options.merge(:skip_decorations => true))
  end

  def update_daily_metrics_for(metric_date)
    metric = Tr8n::Metrics::LanguageDaily.where("language_id = ? and metric_date = ?", self.id, metric_date).first
    metric ||= Tr8n::Metrics::LanguageDaily.create(:language_id => self.id, :metric_date => metric_date)
    metric.update_metrics!
  end

  def total_metric
    @total_metric ||= begin
      metric = Tr8n::Metrics::LanguageTotal.where("language_id = ?", self.id).first
      metric || Tr8n::Metrics::LanguageTotal.create(Tr8n::Metrics::Language.default_attributes.merge(:language_id => self.id))
    end
  end

  def update_total_metrics
    total_metric.update_metrics!
  end

  def prohibited_words
    return [] if curse_words.blank?
    @prohibited_words ||= begin
      wrds = self.curse_words.split(",").collect{|w| w.strip.downcase} 
      wrds << fallback_language.prohibited_words if fallback_language
      wrds.flatten.uniq
    end
  end

  # you can add -bad_words to override the fallback settings rules
  def accepted_prohibited_words
    return [] if curse_words.blank?
    @accepted_prohibited_words ||= begin
      wrds = self.curse_words.split(",").select{|w| w.first=='-'}
      wrds << wrds.collect{|w| w.strip.gsub('-', '').downcase}
      wrds << fallback_language.accepted_prohibited_words if fallback_language
      wrds.flatten.uniq
    end
  end
  
  def bad_words
    @bad_words ||= begin
      bw = prohibited_words + Tr8n::Config.default_language.prohibited_words
      bw.flatten.uniq - accepted_prohibited_words
    end
  end
  
  def clean_sentence?(sentence)
    return true if sentence.blank?

    # we need to solve the downcase problem - it doesn't work for russian and others
    sentence = sentence.downcase

    bad_words.each do |w|
      return false unless sentence.scan(/#{w}/).empty?
    end
    
    true
  end

  def translations_changed!
    # TODO: handle change event - count translations, update total metrics
  end
  
  def recently_added_forum_messages
    @recently_added_forum_messages ||= Tr8n::Forum::Message.where("language_id = ?", self.id).order("created_at desc").limit(5)
  end

  def recently_added_translations
    @recently_added_translations ||= Tr8n::Translation.where("language_id = ?", self.id).order("created_at desc").limit(5)    
  end

  def recently_updated_translations
    @recently_updated_translations ||= begin
      trans =  Tr8n::Translation.where("language_id = ?", self.id)
      trans = trans.where("translation_key_id in (select id from tr8n_translation_keys where level <= ?)", Tr8n::RequestContext.current_translator.level)
      trans.order("updated_at desc").limit(5)
    end
  end
  
  def recently_updated_votes(translator = Tr8n::RequestContext.current_translator)
    @recently_updated_votes ||= Tr8n::TranslationVote.where("translation_id in (select tr8n_translations.id from tr8n_translations where tr8n_translations.language_id = ? and tr8n_translations.translator_id = ?)", self.id, translator.id).order("updated_at desc").limit(5)
  end
  
  def self.create_context_rules(language, json)
    return unless json

    json.each do |key, ctx|
      context = Tr8n::LanguageContext.create(:language    => language,
                                             :keyword     => key,
                                             :description => ctx["description"],
                                             :definition  => {
                                                 "keys"               => ctx["keys"],
                                                 "token_expression"   => ctx["token_expression"],
                                                 "variables"          => ctx["variables"],
                                                 "token_mapping"      => ctx["token_mapping"],
                                                 "default_rule"       => ctx["default_rule"],
                                             }
      )

      if ctx["rules"]
        ctx["rules"].each do |key, rl|
          rule = Tr8n::LanguageContextRule.create(:language_context => context,
                                                  :keyword          => key,
                                                  :description      => rl["description"],
                                                  :examples         => rl["examples"],
                                                  :definition       => {
                                                      "conditions"            =>  rl["rule"],
                                                      "conditions_expression" =>  Tr8n::RulesEngine::Parser.new(rl["rule"]).parse,
                                                  }
          )
        end
      end
    end
  end

  def self.create_language_cases(language, json)
    return unless json

    json.each do |key, ctx|
      lang_case = Tr8n::LanguageCase.create( :language    => language,
                                             :keyword     => key,
                                             :latin_name  => ctx["latin_name"],
                                             :native_name => ctx["native_name"],
                                             :description => ctx["description"],
                                             :application => ctx["application"],
      )

      if ctx["rules"]
        ctx["rules"].each_with_index do |rl, index|
          #puts ["Registering: ", rl["conditions"], rl["operations"]]
          rule = Tr8n::LanguageCaseRule.create(   :language_case    => lang_case,
                                                  :position         => index,
                                                  :description      => rl["description"],
                                                  :examples         => rl["examples"],
                                                  :definition       => {
                                                      "conditions"            =>  rl["conditions"],
                                                      "conditions_expression" =>  Tr8n::RulesEngine::Parser.new(rl["conditions"]).parse,
                                                      "operations"            =>  rl["operations"],
                                                      "operations_expression" =>  Tr8n::RulesEngine::Parser.new(rl["operations"]).parse,
                                                  }
          )
        end
      end
    end
  end

  def self.create_from_json(json)
    language = Tr8n::Language.create(:locale              => json["locale"],
                                     :enabled             => true,
                                     :right_to_left       => json["right_to_left"],
                                     :curse_words         => json["curse_words"],
                                     :english_name        => json["english_name"],
                                     :native_name         => json["native_name"],
                                     :google_key          => json["google_key"],
                                     :myheritage_key      => json["myheritage_key"],
                                     :facebook_key        => json["facebook_key"],
                                     :fallback_language   => json["fallback_language"]
    )

    create_context_rules(language, json["context_rules"])
    create_language_cases(language, json["language_cases"])

    language
  end

  def add_country(country)
    Tr8n::CountryLanguage.find_or_create(country, self)
  end

  def to_api_hash(opts = {})
    hash = {
        :locale         => locale,
        :name           => name,
        :english_name   => english_name,
        :native_name    => native_name,
        :right_to_left  => right_to_left,
        :flag_url       => flag_url
    }

    if opts[:definition]
      hash[:curse_words] = curse_words
      hash[:fallback] = fallback_language.locale if fallback_language

      hash[:contexts] = {}
      language_contexts.each do |ctx|
        hash[:contexts][ctx.keyword] = ctx.to_api_hash(:rules => true)
      end

      hash[:cases] = {}
      language_cases.each do |lc|
        hash[:cases][lc.keyword] = lc.to_api_hash(:rules => true)
      end
    end

    hash
  end
end

