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

require 'json'

module Tr8n
  class Config

    def self.root
      Rails.root
    end

    def self.env
      Rails.env
    end

    def self.config
      @config ||= Tr8n::Utils.load_yml("/config/tr8n/config.yml")
    end

    def self.default_language
      return Tr8n::Language.new(:locale => default_locale) if disabled?
      @default_language ||= Tr8n::Language.by_locale(default_locale) || Tr8n::Language.new(:locale => default_locale)
    end
    
    # only one allowed per system
    def self.system_translator
      @system_translator ||= Tr8n::Translator.where(:user_id => 0, :level => system_level).first || Tr8n::Translator.create(:user_id => 0, :level => system_level)
    end

    def self.default_decoration_tokens
      @default_decoration_tokens ||= Tr8n::Utils.load_yml("/config/tr8n/tokens/decorations.yml", nil)
    end

    def self.default_data_tokens
      @default_data_tokens ||= Tr8n::Utils.load_yml("/config/tr8n/tokens/data.yml", nil)
    end

    def self.enabled?
      config[:enable_tr8n] 
    end
  
    def self.disabled?
      not enabled?
    end

    def self.enable_software_keyboard?
      config[:enable_software_keyboard]
    end

    def self.enable_keyboard_shortcuts?
      config[:enable_keyboard_shortcuts]
    end

    def self.enable_inline_translations?
      config[:enable_inline_translations]
    end
  
    def self.enable_language_cases?
      config[:enable_language_cases]
    end
  
    def self.enable_key_caller_tracking?
      config[:enable_key_caller_tracking]
    end

    def self.enable_google_suggestions?
      config[:enable_google_suggestions]
    end

    def self.google_api_key
      config[:google_api_key]
    end

    def self.enable_glossary_hints?
      config[:enable_glossary_hints]
    end

    def self.enable_dictionary_lookup?
      config[:enable_dictionary_lookup]
    end

    def self.enable_language_flags?
      config[:enable_language_flags]
    end

    def self.enable_language_stats?
      config[:enable_language_stats]
    end

    def self.open_registration_mode?
      config[:open_registration_mode]
    end

    def self.enable_registration_disclaimer?
      config[:enable_registration_disclaimer]
    end

    def self.registration_disclaimer_path
      config[:registration_disclaimer_path] || "/tr8n/common/terms_of_service"
    end
  
    def self.enable_fallback_languages?
      config[:enable_fallback_languages]
    end

    def self.enable_translator_language?
      config[:enable_translator_language]
    end

    def self.enable_admin_translations?
      config[:enable_admin_translations]
    end

    def self.enable_admin_inline_mode?
      config[:enable_admin_inline_mode]
    end

    def self.enable_country_tracking?
      config[:enable_country_tracking]
    end
  
    def self.enable_relationships?
      config[:enable_relationships]
    end

    def self.enable_translator_tabs?
      config[:enable_translator_tabs]
    end

    def self.offline_task_method
      config[:offline_task_method]
    end

    #########################################################
    # Config Sections
    def self.caching
      config[:caching]
    end

    def self.logger
      config[:logger]
    end
  
    def self.site_info
      config[:site_info]
    end


    #########################################################
    # Caching
    #########################################################
    def self.enable_caching?
      caching[:enabled]
    end

    def self.cache_adapter
      caching[:adapter]
    end

    def self.cache_store
      caching[:store]
    end

    def self.cache_version
      caching[:version]
    end
    #########################################################

    #########################################################
    # Logger
    #########################################################
    def self.enable_logger?
      logger[:enabled]
    end

    def self.log_path
      logger[:log_path]
    end

    def self.enable_paranoia_mode?
      logger[:enable_paranoia_mode]
    end
    #########################################################
  
    #########################################################
    # Site Info
    #########################################################
    def self.site_title
      site_info[:title] 
    end

    def self.contact_email
      site_info[:contact_email]
    end

    def self.noreply_email
      site_info[:noreply_email]
    end

    def self.splash_screen
      site_info[:splash_screen]  
    end
  
    def self.default_locale
      site_info[:default_locale]
    end

    def self.default_admin_locale
      site_info[:default_admin_locale]
    end

    def self.base_url
      site_info[:base_url]
    end

    def self.default_url
      site_info[:default_url]
    end

    def self.login_url
      site_info[:login_url]
    end

    def self.signup_url
      site_info[:signup_url]
    end

    def self.media_url
      site_info[:media_url] || base_url
    end

    def self.current_locale_method
      site_info[:current_locale_method]
    end

    def self.tr8n_helpers
      return [] unless site_info[:tr8n_helpers]
      @tr8n_helpers ||= site_info[:tr8n_helpers].collect{|helper| helper.to_sym}
    end

    def self.admin_helpers
      return [] unless site_info[:admin_helpers]
      @admin_helpers ||= site_info[:admin_helpers].collect{|helper| helper.to_sym}
    end
  
    def self.skip_before_filters
      return [] unless site_info[:skip_before_filters]
      @skip_before_filters ||= site_info[:skip_before_filters].collect{|filter| filter.to_sym}
    end

    def self.before_filters
      return [] unless site_info[:before_filters]
      @before_filters ||= site_info[:before_filters].collect{|filter| filter.to_sym}
    end

    def self.after_filters
      return [] unless site_info[:after_filters]
      @after_filters ||= site_info[:after_filters].collect{|filter| filter.to_sym}
    end

    #########################################################
    # site user info
    # The following methods could be overloaded in the initializer
    #########################################################
    def self.site_user_info
      site_info[:user_info]
    end

    def self.current_user_method
      site_user_info[:current_user_method]
    end
  
    def self.user_class_name
      site_user_info[:class_name]
    end

    def self.user_class
      user_class_name.constantize
    end

    def self.user_id(user)
      return 0 unless user
      user.send(site_user_info[:methods][:id])
    rescue Exception => ex
      Tr8n::Logger.error("Failed to fetch user id: #{ex.to_s}")
      0
    end

    def self.user_name(user)
      return "Unknown user" unless user
      user.send(site_user_info[:methods][:name])
    rescue Exception => ex
      Tr8n::Logger.error("Failed to fetch #{user_class_name} name: #{ex.to_s}")
      "Invalid user"
    end

    def self.user_first_name(user)
      return "Unknown user" unless user
      user.send(site_user_info[:methods][:first_name])
    rescue Exception => ex
      Tr8n::Logger.error("Failed to fetch #{user_class_name} name: #{ex.to_s}")
      "Invalid user"
    end

    def self.user_last_name(user)
      return "Unknown user" unless user
      user.send(site_user_info[:methods][:last_name])
    rescue Exception => ex
      Tr8n::Logger.error("Failed to fetch #{user_class_name} name: #{ex.to_s}")
      "Invalid user"
    end

    def self.user_email(user)
      user.send(site_user_info[:methods][:email])
    rescue Exception => ex
      Tr8n::Logger.error("Failed to fetch #{user_class_name} name: #{ex.to_s}")
      "Unknown user"
    end

    def self.user_gender(user)
      return "unknown" unless user
      user.send(site_user_info[:methods][:gender])
    rescue Exception => ex
      Tr8n::Logger.error("Failed to fetch #{user_class_name} name: #{ex.to_s}")
      "unknown"
    end

    def self.user_mugshot(user)
      return silhouette_image unless user
      user.send(site_user_info[:methods][:mugshot])
    rescue Exception => ex
      Tr8n::Logger.error("Failed to fetch #{user_class_name} image: #{ex.to_s}")
      silhouette_image
    end

    def self.user_link(user)
      return "/tr8n" unless user
      user.send(site_user_info[:methods][:link])
    rescue Exception => ex
      Tr8n::Logger.error("Failed to fetch #{user_class_name} link: #{ex.to_s}")
      "/tr8n"
    end

    def self.user_locale(user)
      return default_locale unless user
      user.send(site_user_info[:methods][:locale])
    rescue Exception => ex
      Tr8n::Logger.error("Failed to fetch #{user_class_name} locale: #{ex.to_s}")
      default_locale
    end

    def self.admin_user?(user)
      return false unless user
      user.send(site_user_info[:methods][:admin])
    rescue Exception => ex
      Tr8n::Logger.error("Failed to fetch #{user_class_name} admin flag: #{ex.to_s}")
      false
    end

    def self.guest_user?(user)
      return true unless user
      user.send(site_user_info[:methods][:guest])
    rescue Exception => ex
      Tr8n::Logger.error("Failed to fetch #{user_class_name} guest flag: #{ex.to_s}")
      true
    end

    def self.silhouette_image
      "/assets/tr8n/photo_silhouette.gif"
    end

    def self.system_image
      "/assets/tr8n/photo_system.gif"
    end
  
    #########################################################
    # RULES ENGINE
    #########################################################
    def self.rules_engine
      config[:rules_engine]
    end

    def self.context_rules
      {
          "number" => {
              "variables" => {
              }
          },
          "gender" => {
              "variables" => {
                  "@gender" => "gender",
              }
          },
          "genders" => {
              "variables" => {
                  "@genders" => lambda{|list| list.collect{|u| u.gender}},
                  "@size" => lambda{|list| list.size}
              }
          },
          "date" => {
              "variables" => {
              }
          },
          "time" => {
              "variables" => {
              }
          },
          "list" => {
              "variables" => {
                  "@count" => lambda{|list| list.size}
              }
          },
      }
    end

    def self.allow_nil_token_values?
      rules_engine[:allow_nil_token_values]
    end

    def self.token_classes(category = :data)
      rules_engine["#{category}_token_classes".to_sym].collect{|tc| tc.constantize}
    end

    def self.viewing_user_token_for(label)
      Tr8n::Tokens::Data.new(label, "{#{rules_engine[:viewing_user_token]}:gender}")
    end

    def self.translation_threshold
      rules_engine[:translation_threshold]
    end

    def self.translator_level
      rules_engine[:translator_level] || 1
    end

    def self.default_rank_styles
      @default_rank_styles ||= begin
        styles = {}
        rules_engine[:translation_rank_styles].each do |key, value|
          range = Range.new(*(key.to_s.split("..").map{|v| v.to_i}))
          styles[range] = value
        end
        styles  
      end
    end

    def self.country_from_ip(remote_ip)
      default_country = config["default_country"] || "USA"
      return default_country unless Tr8n::IpAddress.routable?(remote_ip)
      location = Tr8n::IpLocation.find_by_ip(remote_ip)
      (location and location.cntry) ? location.cntry : default_country
    end

    #########################################################
    # LOCALIZATION
    #########################################################
    def self.localization
      config[:localization]
    end

    def self.strftime_symbol_to_token(symbol)
      {
        "%a" => "{short_week_day_name}",
        "%A" => "{week_day_name}",
        "%b" => "{short_month_name}",
        "%B" => "{month_name}",
        "%p" => "{am_pm}",
        "%d" => "{days}",
        "%e" => "{day_of_month}", 
        "%j" => "{year_days}",
        "%m" => "{months}",
        "%W" => "{week_num}",
        "%w" => "{week_days}",
        "%y" => "{short_years}",
        "%Y" => "{years}",
        "%l" => "{trimed_hour}", 
        "%H" => "{full_hours}", 
        "%I" => "{short_hours}", 
        "%M" => "{minutes}", 
        "%S" => "{seconds}", 
        "%s" => "{since_epoch}"
      }[symbol]
    end
  
    def self.default_day_names
      localization[:default_day_names]
    end

    def self.default_abbr_day_names
      localization[:default_abbr_day_names]
    end

    def self.default_month_names
      localization[:default_month_names]
    end

    def self.default_abbr_month_names
      localization[:default_abbr_month_names]
    end
  
    def self.default_date_formats
      localization[:custom_date_formats]
    end

    #########################################################
    # Translator Roles and Levels
    #########################################################
    def self.translator_roles
      config[:translator_roles]
    end

    def self.translator_levels
      @translator_levels ||= begin
        levels = HashWithIndifferentAccess.new
        translator_roles.each do |key, val|
          levels[val] = key
        end
        levels
      end
    end

    def self.manager_level
      1000
    end

    def self.application_level
      100000
    end

    def self.system_level
      1000000
    end

    def self.admin_level
      100000000
    end

    def self.default_translation_key_level
      config[:default_translation_key_level] || 0
    end
  
    #########################################################
    # API
    #########################################################
    def self.api
      config[:api]
    end

    def self.enable_api?
      api[:enabled]
    end

    def self.enable_client_sdk?
      config[:enable_client_sdk]
    end

    def self.enable_browser_cache?
      config[:enable_browser_cache]
    end

    def self.enable_tml?
      config[:enable_tml]
    end

    def self.default_client_interval
      5000
    end

    def self.api_skip_before_filters
      return [] unless api[:skip_before_filters]
      @api_skip_before_filters ||= api[:skip_before_filters].collect{|filter| filter.to_sym}
    end

    def self.api_before_filters
      return [] unless api[:before_filters]
      @api_before_filters ||= api[:before_filters].collect{|filter| filter.to_sym}
    end

    def self.api_after_filters
      return [] unless api[:after_filters]
      @api_after_filters ||= api[:after_filters].collect{|filter| filter.to_sym}
    end

  
    #########################################################
    # Sync Process
    #########################################################
    def self.synchronization
      config[:synchronization]
    end

    def self.synchronization_batch_size
      synchronization[:batch_size]
    end
    
    def self.synchronization_server
      synchronization[:server]
    end
    
    def self.synchronization_key
      synchronization[:key]
    end

    def self.synchronization_secret
      synchronization[:secret]
    end

    def self.synchronization_all_languages?
      synchronization[:all_languages]
    end

    def self.synchronization_push_enabled?
      synchronization[:enable_push]
    end
    
    def self.synchronization_push_servers
      synchronization[:push_servers]
    end
    
    #########################################################
    ### RELATIONSHIP AND CONFIGURATION KEYS
    #########################################################
    def self.init_relationship_keys
      puts "Initializing default relationship keys..." unless env.test?

      Tr8n::RelationshipKey.delete_all if env.test? or env.development?
      
      sys_translator = system_translator
      
      default_relationship_keys.each do |key, data|
        puts key unless env.test?
        rkey = Tr8n::RelationshipKey.find_or_create(key)
        rkey.description ||= data.delete(:description)
        rkey.level = curator_level # only admins and curators can see them for now
        rkey.save
        
        data.each do |locale, labels|
          language = Tr8n::Language.by_locale(locale)
          next unless language
          labels = [labels].flatten # there could be a few translation variations
          labels.each do |lbl|
            trn = rkey.add_translation(lbl, nil, language, sys_translator)
          end
        end
      end
    end
    
    def self.default_relationship_keys
      @default_relationship_keys ||= Tr8n::Utils.load_yml("/config/tr8n/data/default_relationship_keys.yml", nil)
    end
    
    def self.init_configuration_keys
      puts "Initializing default configuration keys..." unless env.test?

      Tr8n::ConfigurationKey.delete_all if env.test? or env.development?
      
      sys_translator = system_translator
      
      default_configuration_keys.each do |key, value|
        puts key unless env.test?
        rkey = Tr8n::ConfigurationKey.find_or_create(key, value[:label], value[:description])
        rkey.level = curator_level # only admins and curators can see them for now
        rkey.save
        
        translations = value[:translations] || {}
        translations.each do |locale, lbl|
          language = Tr8n::Language.by_locale(locale)
          next unless language
          rkey.add_translation(lbl, nil, language, sys_translator)
        end
      end
    end
    
    def self.default_configuration_keys
      @default_configuration_keys ||= Tr8n::Utils.load_yml("/config/tr8n/data/default_configuration_keys.yml", nil)
    end

  end
end
