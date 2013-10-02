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
#-- Tr8n::TranslationKey Schema Information
#
# Table name: tr8n_translation_keys
#
#  id                   INTEGER         not null, primary key
#  type                 varchar(255)    
#  key                  varchar(255)    not null
#  label                text            not null
#  description          text            
#  verified_at          datetime        
#  translation_count    integer         
#  admin                boolean         
#  locale               varchar(255)    
#  level                integer         default = 0
#  synced_at            datetime        
#  created_at           datetime        not null
#  updated_at           datetime        not null
#
# Indexes
#
#  tr8n_tk_k    (key) UNIQUE
#
#++

require 'digest/md5'

class Tr8n::TranslationKey < ActiveRecord::Base
  self.table_name = :tr8n_translation_keys
  attr_accessible :key, :label, :description, :verified_at, :translation_count, :admin, :locale, :level, :synced_at
  
  has_many :translations,             :class_name => "Tr8n::Translation",           :dependent => :destroy
  has_many :translation_key_locks,    :class_name => "Tr8n::TranslationKeyLock",    :dependent => :destroy
  has_many :translation_key_sources,  :class_name => "Tr8n::TranslationKeySource",  :dependent => :destroy
  has_many :translation_sources,      :class_name => "Tr8n::TranslationSource",     :through => :translation_key_sources
  has_many :translation_domains,      :class_name => "Tr8n::TranslationDomain",     :through => :translation_sources
  has_many :translation_key_comments, :class_name => "Tr8n::TranslationKeyComment", :dependent => :destroy, :order => "created_at desc"



  def self.cache_key(key)
    "translation_key_[#{key}]"
  end

  def cache_key
    self.class.cache_key(key)
  end

  def self.find_or_create(label, desc = "", options = {})
    key = generate_key(label, desc).to_s

    tkey = Tr8n::RequestContext.current_source.translation_key_for_key(key) if Tr8n::RequestContext.current_source
    tkey ||= begin
      # pp "key for label #{label} not found in cache"
      existing_key = where(:key => key).first
      
      existing_key ||= begin
        level = options[:level] || Tr8n::RequestContext.block_options[:level] || Tr8n::Config.default_translation_key_level
        role_key = options[:role] || Tr8n::RequestContext.block_options[:role]
        if role_key
          level = Tr8n::Config.translator_roles[role_key]
          raise Tr8n::Exception("Unknown dashboard role: #{role_key}") unless level
        end
        locale = options[:locale] || Tr8n::RequestContext.block_options[:default_locale] || Tr8n::Config.default_locale
        create( :key => key.to_s, 
                :label => label, 
                :description => desc, 
                :locale => locale,
                :level => level,
                :admin => Tr8n::RequestContext.block_options[:admin] )
      end

      track_source(existing_key, options)
      existing_key
    end
  end

  def sources(app = Tr8n::RequestContext.container_application)
    translation_sources.where(:application_id => app.id)
  end

  # creates associations between the translation keys and sources
  # used for the site map and javascript support
  def self.track_source(translation_key, options = {})
    # source can be passed into an individual key, or as a block or fall back on the controller/action
    source = options[:source] || Tr8n::RequestContext.current_source_from_block_options || Tr8n::RequestContext.current_source
    return unless source

    translation_source = Tr8n::TranslationSource.find_or_create(source, options[:application] || Tr8n::RequestContext.container_application)

    # each key is associated with one or more sources
    translation_key_source = Tr8n::TranslationKeySource.find_or_create(translation_key, translation_source)
    Tr8n::RequestContext.current_source.clear_cache_for_language

    # for debugging purposes only - this will track the actual location of the key in the source
    if Tr8n::Config.enable_key_caller_tracking?    
      options[:caller] ||= caller
      options[:caller_key] = options[:caller].is_a?(Array) ? options[:caller].join(", ") : options[:caller].to_s
      options[:caller_key] = generate_key(options[:caller_key])
      translation_key_source.update_details!(options)
    end
  end

  def self.generate_key(label, desc = "")
    "#{Digest::MD5.hexdigest("#{label};;;#{desc}")}~"[0..-2]
  end

  # for key merging
  def reset_key!
    Tr8n::Cache.delete(cache_key)
    self.update_attributes(:key => self.class.generate_key(label, description))
  end
  
  def tokenized_label
    @tokenized_label ||= Tr8n::TokenizedLabel.new(label)
  end

  def data_tokens
    @data_tokens ||= begin
      Tr8n::Tokens::Base.register_tokens(label, :data)
    end
  end

  def allowed_tokens
    @allowed_tokens ||= begin
      data_tokens.select{|token| token.allowed_in_translation?}
    end
  end

  def allowed_token_names
    @allowed_token_names ||= allowed_tokens.collect{|token| token.name}
  end

  def allowed_token?(token)
    allowed_token_names.include?(token.name)
  end

  def implied_tokens
    @implied_tokens ||= data_tokens.select{|token| token.implied? and not allowed_token?(token)}
  end

  def decoration_tokens
    @decoration_tokens ||= begin
      dt = Tr8n::Tokens::Decoration.new(label)
      dt.parse
      dt.tokens
    end
  end

  def sanitized_label
    @sanitized_label ||= begin
      lbl = label.clone
      data_tokens.each do |token|
        lbl = token.prepare_label_for_translator(lbl, self.language)
      end
      lbl
    end
  end

  def breadcrumb_label
    return sanitized_label if sanitized_label.length < 50
    sanitized_label[0..50] + '...'
  end

  def tokenless_label
    @tokenless_label ||= begin
      lbl = label.clone
      data_tokens.each_with_index do |token, index|
        lbl = token.prepare_label_for_suggestion(lbl, index, self.language)
      end
      lbl
    end
  end

  def words
    return [] if label.blank?

    @words ||= begin
      clean_label = sanitized_label
      parts = []
      clean_label = clean_label.gsub(/[\,\.\;\!\-\:\'\"\[\]{}]/, "")

      clean_label.split(" ").each do |w|
        parts << w.strip.capitalize if w.length > 3
      end
      parts
    end
  end

  # comments are left for a specific settings
  def comments(language = Tr8n::RequestContext.current_language)
    Tr8n::TranslationKeyComment.where("language_id = ? and translation_key_id = ?", language.id, self.id).all
  end

  # returns only the tokens that depend on one or more rules of the settings, if any defined for the settings
  def language_context_dependant_tokens(language = Tr8n::RequestContext.current_language)
    tokens = {}

    viewing_user = Tr8n::Config.viewing_user_token_for(label)

    (data_tokens + [viewing_user]).each do |token|
      next if tokens[token.short_name]
      ctx = token.context_for_language(language, :silent => true)
      tokens[token.short_name] = token if ctx
    end

    tokens.values
  end

  # determines whether the key can have rules generated for the settings
  def permutable?(language = Tr8n::RequestContext.current_language)
    @permutable ||= {}
    @permutable[language.locale] ||= language_context_dependant_tokens(language).any?
  end

  def glossary
    @glossary ||= Tr8n::Glossary.where("keyword in (?)", words).order("keyword asc").all
  end
  
  def glossary?
    not glossary.empty?
  end
  
  def lock_for(language)
    @lock_by_language ||= {}
    @lock_by_language[language.locale] ||= begin
      Tr8n::Cache.fetch(Tr8n::TranslationKeyLock.cache_key(language.locale, key)) do
        Tr8n::TranslationKeyLock.find_or_create(self, language)
      end
    end
  end
  
  def lock!(language = Tr8n::RequestContext.current_language, translator = Tr8n::RequestContext.current_translator)
    lock_for(language).lock!(translator)
  end

  def unlock!(language = Tr8n::RequestContext.current_language, translator = Tr8n::RequestContext.current_translator)
    lock_for(language).unlock!(translator)
  end

  def unlock_all!
    locks.each do |lock|
      lock.unlock!
    end
  end
  
  def locked?(language = Tr8n::RequestContext.current_language)
    lock_for(language).locked?
  end

  def unlocked?(language = Tr8n::RequestContext.current_language)
    not locked?(language)
  end

  def followed?(translator = nil)
    translator ||= (Tr8n::RequestContext.current_user_is_translator? ? Tr8n::RequestContext.current_translator : nil)
    return false unless translator
    Tr8n::TranslatorFollowing.following_for(translator, self)
  end
    
  def commented?(language, translator = nil)
    translator ||= (Tr8n::RequestContext.current_user_is_translator? ? Tr8n::RequestContext.current_translator : nil)
    return false unless translator
    Tr8n::TranslationKeyComment.where("translator_id = ? and translation_key_id = ? and language_id = ?", 
                                       translator.id, self.id, language.id).first
  end


  def add_translation(label, context = nil, language = Tr8n::RequestContext.current_language, translator = Tr8n::RequestContext.current_translator)
    raise Tr8n::Exception.new("The dashboard is blocked and cannot submit translations") if translator.blocked?
    raise Tr8n::Exception.new("The sentence contains dirty words") unless language.clean_sentence?(label)
    translation = Tr8n::Translation.new(:translation_key => self, :language => language, :translator => translator, :label => label, :context => context)
    translation.save_with_log!(translator)
    translation.vote!(translator, 1)
    translation
  end

  def add_source(src)
    Tr8n::TranslationKeySource.find_or_create(self, src)
  end

  # returns all translations for the key, settings and minimal rank
  def translations_for(language = nil, rank = nil)
    translations = Tr8n::Translation.where("translation_key_id = ?", self.id)
    if language
      translations = translations.where("language_id in (?)", [language].flatten.collect{|lang| lang.id})
    end
    translations = translations.where("rank >= ?", rank) if rank
    translations.order("rank desc").all
  end

  def valid_translations_for_language(language)
    translations_for(language, Tr8n::RequestContext.current_application.threshold)
  end

  # used by the inline popup dialog, we don't want to show blocked translations
  def inline_translations_for(language)
    translations_for(language, -50)
  end

  def translations_cache_key(language)
    "translations_#{language.locale}_#{key}"
  end
  
  def clear_translations_cache_for_language(language = Tr8n::RequestContext.current_language)
    Tr8n::Cache.delete(translations_cache_key(language)) 
  end  

  # used by all translation methods
  def cached_translations_for_language(language)
    if Tr8n::RequestContext.current_source
      translations = Tr8n::RequestContext.current_source.valid_translations_for_key_and_language(self.key, language)
    end

    # pp "found #{translations.count} cached translations for #{self.label}" if translations
    translations || valid_translations_for_language(language)
  end

  # Coverts:
  #
  # {"actor"=>{"gender"=>"true", "value"=>"true"}, "count"=>{"number"=>"true"}}
  #
  # Into:
  #
  # {"actor_@0"=>["gender:male", "gender:female", "gender:other"],
  # "actor_@1"=>["value:vowels", "value:other"],
  # "count_@0"=>["number:one", "number:few", "number:many", "number:other"]}

  def self.generate_rules_set(language, dependencies)
    return if dependencies.blank?

    token_rules = {}
    dependency_mapping = {}

    dependencies.each do |token_name, context_keywords|
      context_keywords.keys.each_with_index do |context_keyword, index|
        token_key = token_name + "_@#{index}"
        dependency_mapping[token_key] = token_name

        context = Tr8n::LanguageContext.by_keyword_and_language(context_keyword, language)
        token_rules[token_key] = [] unless token_rules[token_key]
        context.rules.each do |rule|
          token_rules[token_key] << "#{context.keyword}:#{rule.keyword}"
        end
      end
    end

    token_rules
  end

  # Converts:
  #
  # [{"count_@0"=>"number:one"}, {"count_@0"=>"number:few"}, {"count_@0"=>"number:many"}, {"count_@0"=>"number:other"}]
  #
  # Into:
  #
  # {"count"=>{"number"=>"one"}}, {"count"=>{"number"=>"few"}}, {"count"=>{"number"=>"many"}}, {"count"=> {"number" => "other"}}]
  def self.generate_rules_combinations(rules_combinations)
    combinations = []
    rules_combinations.each do |comb|
      combination = {}
      comb.each do |token_name, value|
        token_name = token_name.gsub(/_@(\d)+$/, '')
        combination[token_name] ||= {}
        context, rule = value.split(':', 2)
        combination[token_name][context] = rule
      end
      combinations << combination
    end

    combinations
  end

  def generate_translations_for_rules_combinations(language, translator, dependencies)
    return if dependencies.blank?

    new_translations = []

    combinations = Tr8n::TranslationKey.generate_rules_combinations(Tr8n::TranslationKey.generate_rules_set(language, dependencies).combinations)

    contexts = translations_for(language).collect{|t| t.context}

    combinations.each do |context|
      next if contexts.include?(context) # if there is already a translation for the contex - don't generate it
      new_translations << Tr8n::Translation.create(:translation_key => self, :language => language, :translator => translator, :label => sanitized_label, :context => context)
    end
    
    new_translations
  end

  def self.random
    self.limit(1).offset(rand(count-1))
  end

  ###########################################################################
  # returns back grouped by context - used by API - deprecated - 
  # MUST CHANGE JS to use the new method valid_translations_with_rules
  ###########################################################################
  def find_all_valid_translations(translations)
    if translations.empty?
      return {:id => self.id, :key => self.key, :label => self.label, :original => true}
    end
    
    # if the first translation does not depend on any of the context rules
    # use it... we don't care about the rest of the rules.
    if translations.first.context.blank?
      return {:id => self.id, :key => self.key, :label => translations.first.label}
    end
    
    # build a context hash for every kind of context rules combinations
    # only the first one in the list should be used
    context_hash_matches = {}
    valid_translations = []
    translations.each do |translation|
      context_key = translation.context || ""
      next if context_hash_matches[context_key]
      context_hash_matches[context_key] = true
      if translation.context
        valid_translations << {:label => translation.label, :context => translation.context.dup}
      else
        valid_translations << {:label => translation.label}
      end
    end

    # always add the default one at the end, so if none of the rules matched, use the english one
    valid_translations << {:label => self.label} unless context_hash_matches[""]
    {:id => self.id, :key => self.key, :labels => valid_translations}
  end
  ###########################################################################

  def find_first_valid_translation(language, translator, token_values, opts = {})
    cached_translations_for_language(language).each do |translation|
      return translation if translation.matches_rules?(token_values)
    end

    if opts[:fallback_onto_translator]
      if translator.fallback_language and not translator.fallback_language.default?
        fallback_language = translator.fallback_language
      end
    elsif opts[:fallback_onto_language]
      if language.fallback_language and not language.fallback_language.default?
        fallback_language = language.fallback_language
      end
    end

    if fallback_language
      return find_first_valid_translation(fallback_language, translator, token_values, opts)
    end

    nil
  end

  def valid_translations_with_rules(language, opts = {})
    opts[:threshold] ||= Tr8n::RequestContext.current_application.threshold

    translations = translations_for(language, opts[:threshold])
    return [] if translations.empty?
    
    # if the first translation does not depend on any of the context rules
    # use it... we don't care about the rest of the rules.
    return [translations.first.to_api_hash] if translations.first.context.blank?
    
    # build a context hash for every kind of context rules combinations
    # only the first one in the list should be used
    context_matches = {}
    valid_translations = []
    translations.each do |translation|
      next if context_matches[translation.context]
      context_matches[translation.context] = true
      valid_translations << translation.to_api_hash
    end

    valid_translations
  end

  def translate(language = Tr8n::RequestContext.current_language, token_values = {}, options = {})
    if options[:api] # deprecated
      return find_all_valid_translations(cached_translations_for_language(language))
    end

    if Tr8n::Config.disabled? or (language == self.language)
      return substitute_tokens(self.language, label, token_values, options.merge(:fallback => false)).html_safe
    end

    translation_options = {}
    if Tr8n::Config.enable_translator_language? and Tr8n::RequestContext.current_user_is_translator?
      translation_options[:fallback_onto_translator] = true
    elsif Tr8n::Config.enable_fallback_languages?
      translation_options[:fallback_onto_language] = true
    end

    #Tr8n::Logger.measure("Translation for: #{label} took") do
    translation = find_first_valid_translation(language, Tr8n::RequestContext.current_translator, token_values, translation_options)
    #end

    decorator = options[:decorator] || Tr8n::RequestContext.container_application.decorator

    if translation
      # if you want to present the label in it's sanitized form - for the phrase list
      if options[:default_language]
        translation = decorator.decorate_translation(language, self, sanitized_label, options.merge(:translated => true)).html_safe
      else
        translated_label = substitute_tokens(translation.language, translation.label, token_values, options)
        translation = decorator.decorate_translation(translation.language, self, translated_label, options.merge(:translated => true, :fallback => (translation.language != language))).html_safe
      end
    else
      # no translation found
      translated_label = substitute_tokens(self.language, label, token_values, options)
      translation = decorator.decorate_translation(self.language, self, translated_label, options.merge(:translated => false)).html_safe
    end

    translation
  end

  ###############################################################
  ## Substitution and Decoration Related Stuff
  ###############################################################

  # this is done when the translations engine is disabled
  def self.substitute_tokens(language, label, tokens, options = {})
    return label.to_s if options[:skip_substitution] 
    Tr8n::TranslationKey.new(:label => label.to_s).substitute_tokens(language, label.to_s, tokens, options)
  end

  def substitute_tokens(language, translated_label, token_values, options = {})
    processed_label = translated_label.to_s.dup

    # substitute data tokens
    Tr8n::Tokens::Base.register_tokens(processed_label, :data).each do |token|
      next unless allowed_token?(token)
      processed_label = token.substitute(self, language, processed_label, token_values, options)
    end

    Tr8n::Tokens::Decoration.new(processed_label, token_values, :allowed_tokens => decoration_tokens).substitute
  end
  
  def default_decoration(language = Tr8n::RequestContext.current_language, options = {})
    Tr8n::RequestContext.current_application.decorator.decorate_translation_key(language, self, options)
  end

  def level
    return 0 if super.nil?
    super
  end
  
  def can_be_translated?(translator = nil)
    translator ||= (Tr8n::RequestContext.current_user_is_translator? ? Tr8n::RequestContext.current_translator : nil)
    if translator 
      return false if locked? and not translator.manager? 
      translator_level = translator.level
    else   
      return false if locked?
      translator_level = 0
    end
    translator_level >= level
  end

  def can_be_locked?(translator = nil)
    translator ||= (Tr8n::RequestContext.current_user_is_translator? ? Tr8n::RequestContext.current_translator : nil)
    return false unless translator
    translator.admin? or translator.manager?
  end

  def can_be_unlocked?(translator = nil)
    translator ||= (Tr8n::RequestContext.current_user_is_translator? ? Tr8n::RequestContext.current_translator : nil)
    return false unless translator
    translator.admin? or translator.manager?
  end

  def verify!(time = Time.now)
    update_attributes(:verified_at => time)
  end
      
  def translations_changed!(language = Tr8n::RequestContext.current_language)
    return unless language

    Tr8n::RequestContext.current_source.clear_cache_for_language(language) if Tr8n::RequestContext.current_source

    # update timestamp and clear cache
    update_translation_count! 

    # notify all settings sources that translation has changed
    sources.each do |source|
      source.touch
      # Tr8n::TranslationSourceLanguage.touch(source, settings)
      # may need to be a delayed job
      source.clear_cache_for_language(language)
    end
  end
        
  def update_translation_count!
    update_attributes(:translation_count => Tr8n::Translation.count(:conditions => ["translation_key_id = ?", self.id]))
  end

  def source_map
    @source_map ||= begin
      map = {}
      sources.each do |source|
        (map[source.application.name] ||= []) << source
      end
      map
    end
  end

  ###############################################################
  ## Offline Tasks
  ###############################################################
  def update_metrics!(language = Tr8n::RequestContext.current_language, opts = {})
    Tr8n::OfflineTask.schedule(self.class.name, :update_metrics_offline, {
                               :translation_key_id => self.id, 
                               :language_id => language.id
    })
  end

  def self.update_metrics_offline(opts)
    tkey = Tr8n::TranslationKey.find(opts[:translation_key_id])
    language = Tr8n::Language.find(opts[:language_id])
    Tr8n::TranslationKeySource.where("translation_key_id = ?", tkey.id).all.each do |tks|
      next unless tks.source
      tks.source.total_metric.update_metrics!
    end
    language.total_metric.update_metrics!
  end

  ###############################################################
  ## Synchronization Methods
  ###############################################################
  def mark_as_synced!
    update_attributes(:synced_at => Time.now + 2.seconds)
  end
    
  def to_api_hash(opts = {})
    hash = { 
      "id" => self.id,
      "key" => self.key, 
      "label" => self.label, 
      "description" => self.description.blank? ? nil : self.description,
      "locale" => (locale || Tr8n::Config.default_locale), 
    }
    
    unless opts[:translations] == false
      hash["translations"] = opts[:translations] || translations_for(opts[:languages], opts[:threshold] || Tr8n::RequestContext.current_application.threshold).collect{|t| t.to_api_hash(opts)}
    end

    hash
  end

  def transations_sync_hashes(opts = {})
    @transations_sync_hashes ||= begin
      translations.collect{|t| t.to_api_hash(:comparible => true)}
    end  
  end
    
  def self.can_create_from_sync_hash?(tkey_hash, translator, opts = {})
    return false if tkey_hash["key"].blank? or tkey_hash["label"].blank? or tkey_hash["locale"].blank?
    true
  end
      
  # create translation key from API hash
  def self.create_from_sync_hash(tkey_hash, default_translator, opts = {})
    return unless can_create_from_sync_hash?(tkey_hash, default_translator, opts)
    
    # find or create translation key  
    tkey = Tr8n::TranslationKey.find_or_create(tkey_hash["label"], tkey_hash["description"])

    # we will keep the translations that need to be sent back
    remaining_translations = tkey.transations_sync_hashes(opts).dup

    added_trans = []
    (tkey_hash["translations"] || []).each do |thash|
      remaining_translations.delete(thash)

      # if the translation came from a linked dashboard, use the dashboard
      translator = default_translator
      if thash["translator_id"] # incoming translations from the remote server
        translator = Tr8n::Translator.find_by_id(thash["translator_id"]) || default_translator
      elsif thash["dashboard"]
        translator = Tr8n::Translator.create_from_sync_hash(thash["dashboard"], opts) || default_translator
      end
      
      # don't insert duplicate translations
      comparible_hash = thash.slice("locale", "label", "rules")
      next if tkey.transations_sync_hashes.include?(comparible_hash)
      
      translation = Tr8n::Translation.create_from_sync_hash(tkey, translator, thash, opts)
      
      translation.mark_as_synced! if translation
    end

    # need to send back translations that have not been added, but exist in the system
    # pp :after, remaining_sync_hashes
    [tkey, remaining_translations]
  end

  ###############################################################
  ## Feature Methods
  ###############################################################

  def language
    @language ||= (locale ? Tr8n::Language.by_locale(locale) : Tr8n::Config.default_language)
  end

  def title
    "Original Phrase in {language}"
  end
  
  def self.help_url
    '/tr8n/help'
  end
  
  def suggestion_label
    tokenless_label.gsub('"', '\"')
  end
  
  def suggestions?
    true 
  end

  def rules?
    translation_tokens? or Tr8n::RequestContext.current_language.has_rules?
  end
  
  def dictionary?
    true 
  end

  def sources?
    true
  end

  ###############################################################
  ## Search Methods
  ###############################################################
  def self.all_restricted_ids
    Tr8n::TranslationKey.find(:all, 
        :select => "distinct tr8n_translation_keys.id",
        :conditions => ["c.state = ?", 'restricted'],
        :joins => [
          "join tr8n_translation_key_sources as tks on tr8n_translation_keys.id = tks.translation_key_id",
          "join tr8n_component_sources as cs on tks.translation_source_id = cs.translation_source_id",
          "join tr8n_components as c on cs.component_id = c.id"
        ]
    ).collect{|key| key.id}
  end
      
  def self.filter_phrase_type_options
    [["all", "any"], 
     ["without translations", "without"], 
     ["with translations", "with"],
     ["followed by me", "followed"]
    ] 
  end
  
  def self.filter_phrase_status_options
     [["any", "any"],
      ["pending approval", "pending"], 
      ["approved", "approved"]]
  end

  def self.filter_phrase_lock_options
     [["locked and unlocked", "any"],
      ["locked only", "locked"], 
      ["unlocked only", "unlocked"]]
  end
  
  def self.for_params(params)
    # only show keys of settings other than the kyes themselves
    results = self.where("tr8n_translation_keys.locale <> ?", Tr8n::RequestContext.current_language.locale)

    # only show keys for the current applications - determined through sources
    if params[:application]
      results = results.joins(:translation_sources).where("tr8n_translation_sources.application_id = ?", params[:application].id)
    end

    if params[:source]
      results = results.joins(:translation_sources).where("tr8n_translation_sources.id = ?", params[:source].id)
    end

    # only show keys translators has rights to view
    if Tr8n::RequestContext.current_user_is_translator?
      results = results.where("level is null or level <= ?", Tr8n::RequestContext.current_translator.level)
    else
      results = results.where("level is null or level = 0")
    end

    # allow translators to query keys    
    unless params[:search].blank?
      results = results.where("(tr8n_translation_keys.label like ? or tr8n_translation_keys.description like ?)", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    # for with and approved, allow user to specify the kinds
    if params[:phrase_type] == "with"
      results = results.where("tr8n_translation_keys.id in (select tr8n_translations.translation_key_id from tr8n_translations where tr8n_translations.language_id = ?)", Tr8n::RequestContext.current_language.id)
      
      # if approved, ensure that translation key is locked
      if params[:phrase_status] == "approved" 
        results = results.where("tr8n_translation_keys.id in (select tr8n_translation_key_locks.translation_key_id from tr8n_translation_key_locks where tr8n_translation_key_locks.language_id = ? and tr8n_translation_key_locks.locked = ?)", Tr8n::RequestContext.current_language.id, true)
      
        # if approved, ensure that translation key does not have a lock or unlocked
      elsif params[:phrase_status] == "pending" 
        results = results.where("tr8n_translation_keys.id not in (select tr8n_translation_key_locks.translation_key_id from tr8n_translation_key_locks where tr8n_translation_key_locks.language_id = ? and tr8n_translation_key_locks.locked = ?)", Tr8n::RequestContext.current_language.id, true)
      end
            
    elsif params[:phrase_type] == "without"
      results = results.where("tr8n_translation_keys.id not in (select tr8n_translations.translation_key_id from tr8n_translations where tr8n_translations.language_id = ?)", Tr8n::RequestContext.current_language.id)
      
    elsif params[:phrase_type] == "followed" and Tr8n::RequestContext.current_user_is_translator?
      results = results.where("tr8n_translation_keys.id in (select tr8n_translator_following.object_id from tr8n_translator_following where tr8n_translator_following.translator_id = ? and tr8n_translator_following.object_type = ?)", Tr8n::RequestContext.current_translator.id, 'Tr8n::TranslationKey')
    end
    
    if params[:phrase_lock] == "locked"
      results = results.where("tr8n_translation_keys.id in (select tr8n_translation_key_locks.translation_key_id from tr8n_translation_key_locks where tr8n_translation_key_locks.language_id = ? and tr8n_translation_key_locks.locked = ?)", Tr8n::RequestContext.current_language.id, true)
      
    elsif params[:phrase_lock] == "unlocked"  
      results = results.where("tr8n_translation_keys.id not in (select tr8n_translation_key_locks.translation_key_id from tr8n_translation_key_locks where tr8n_translation_key_locks.language_id = ? and tr8n_translation_key_locks.locked = ?)", Tr8n::RequestContext.current_language.id, true)
    end
    
    results.order("created_at desc").uniq
  end    
end
