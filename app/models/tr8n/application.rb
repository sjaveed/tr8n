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
#-- Tr8n::Application Schema Information
#
# Table name: tr8n_applications
#
#  id             INTEGER         not null, primary key
#  key            varchar(255)    
#  secret         varchar(255)    
#  name           varchar(255)    
#  description    varchar(255)    
#  created_at     datetime        not null
#  updated_at     datetime        not null
#
# Indexes
#
#  tr8n_apps    (key) 
#
#++

class Tr8n::Application < ActiveRecord::Base
  self.table_name = :tr8n_applications
  attr_accessible :key, :name, :description, :default_language

  has_many :components, :class_name => 'Tr8n::Component', :dependent => :destroy

  has_many :translation_domains, :class_name => 'Tr8n::TranslationDomain', :dependent => :destroy
  alias :domains :translation_domains

  has_many :translation_sources, :class_name => 'Tr8n::TranslationSource', :dependent => :destroy
  alias :sources :translation_sources

  belongs_to :default_language, :class_name => 'Tr8n::Language', :foreign_key => :default_language_id
  has_many :application_languages, :class_name => 'Tr8n::ApplicationLanguage', :dependent => :destroy
  has_many :languages, :class_name => 'Tr8n::Language', :through => :application_languages

  has_many :application_translators, :class_name => 'Tr8n::ApplicationTranslator', :dependent => :destroy
  has_many :translators, :class_name => 'Tr8n::Translator', :through => :application_translators

  before_create :generate_keys

  serialize :definition

  after_destroy :clear_cache
  after_save :clear_cache

  def self.cache_key(key)
    "application_[#{key.to_s}]"
  end

  def cache_key
    self.class.cache_key(key)
  end

  def self.for(key)
    Tr8n::Cache.fetch(cache_key(key)) do 
      where("key = ?", key.to_s).first
    end  
  end

  def self.options
    Tr8n::Application.all.order("name asc").collect{|app| [app.name, app.id]}
  end

  def featured_languages
    @featured_languages ||= application_languages.where("featured_index != null").order('featured_index asc').collect{|aplang| aplang.language}
  end

  def clear_cache
    Tr8n::Cache.delete(cache_key)
  end

  def add_translator(translator)
    Tr8n::ApplicationTranslator.find_or_create(self, translator)
  end

  def add_language(language)
    Tr8n::ApplicationLanguage.find_or_create(self, language)
  end

  def remove_language(language)
    al = Tr8n::ApplicationLanguage.where(:application_id => self.id, :language_id => language.id).first
    al.destroy if al
    al
  end

  def create_oauth_token(klass, translator, scope, expire_in)
    token = klass.new
    token.application = self
    token.translator = translator
    token.scope = scope
    token.generate_token
    token.expire_in(expire_in)
    token.save!
    token    
  end

  def create_request_token(translator, scope = 'basic', expire_in = 3.months)
    create_oauth_token(Tr8n::Oauth::RequestToken, translator, scope, expire_in) 
  end

  def create_refresh_token(translator, scope = 'basic', expire_in = 5.months)
    create_oauth_token(Tr8n::Oauth::RefreshToken, translator, scope, expire_in) 
  end

  def create_client_token(scope = 'basic', expire_in = 3.months)
    create_oauth_token(Tr8n::Oauth::ClientToken, nil, scope, expire_in) 
  end

  def create_access_token(translator, scope = 'basic', expire_in = 3.months)
    create_oauth_token(Tr8n::Oauth::AccessToken, translator, scope, expire_in) 
  end

  def find_valid_token_for_scope(tokens, scope)
    valid_token = nil
    tokens.each do |token|
      if token.valid_token?(scope) and valid_token.nil?
        valid_token = token
      else
        token.destroy
      end
    end
    valid_token
  end

  def find_or_create_request_token(translator, scope = 'basic', expire_in = 3.months)
    tokens = Tr8n::Oauth::RequestToken.where("application_id = ? and translator_id = ?", self.id, translator.id).all
    valid_token = find_valid_token_for_scope(tokens, scope)
    valid_token ||= create_request_token(translator, scope, expire_in)

    valid_token    
  end

  def find_or_create_access_token(translator, scope = 'basic', expire_in = 3.months)
    tokens = Tr8n::Oauth::AccessToken.where("application_id = ? and translator_id = ?", self.id, translator.id).all
    valid_token = find_valid_token_for_scope(tokens, scope)
    valid_token ||= create_access_token(translator, scope, expire_in)
    Tr8n::ApplicationTranslator.touch(self, translator)

    valid_token
  end  

  def reset_secret!
    self.secret = Tr8n::Config.guid
    save
  end

  def default_classes
    {
        "tr8n_not_translated" => "border-bottom: 2px solid red !important;",
        "tr8n_translated"     => "border-bottom: 2px solid green !important;",
        "tr8n_fallback"       => "border-bottom: 2px solid yellow !important;",
        "tr8n_language_case"  => "border: 1px dotted blue !important;",
        "tr8n_locked"         => "border-bottom: 2px solid blue !important;"
    }
  end

  def classes
    self.definition ||= {}
    unless definition["classes"]
      definition["classes"] = default_classes
      save
    end
    definition["classes"]
  end

  def styles
    html = []
    cls = feature_enabled?(:decorations) ? classes : default_classes
    cls.each do |name, value|
      html << ".#{name} { #{value} }"
    end
    html.join("\n").html_safe
  end

  def default_shortcuts
    {
        "Ctrl+Shift+S"  =>  {"description"=>"Displays Tr8n shortcuts", "script"=>"Tr8n.UI.Lightbox.show('/tr8n/help/lb_shortcuts', {width:400});"},
        "Ctrl+Shift+I"  =>  {"description"=>"Turns on/off inline translations", "script"=>"Tr8n.UI.LanguageSelector.toggleInlineTranslations();"},
        "Ctrl+Shift+L"  =>  {"description"=>"Shows/hides settings selector", "script"=>"Tr8n.UI.LanguageSelector.show(true);"},
        "Ctrl+Shift+N"  =>  {"description"=>"Displays notifications", "script"=>"Tr8n.UI.Lightbox.show('/tr8n/translator/notifications/lb_notifications', {width:600});"},
        "Ctrl+Shift+K"  =>  {"description"=>"Adds software keyboard for each entry field", "script"=>"Tr8n.Utils.toggleKeyboards();"},
        "Ctrl+Shift+C"  =>  {"description"=>"Display current component status", "script"=>"Tr8n.UI.Lightbox.show('/tr8n/help/lb_source?source=' + Tr8n.source, {width:420});"},
        "Ctrl+Shift+T"  =>  {"description"=>"Displays Tr8n statistics", "script"=>"Tr8n.UI.Lightbox.show('/tr8n/help/lb_stats', {width:420});"},
        "Ctrl+Shift+D"  =>  {"description"=>"Debug Tr8n Proxy", "script"=>"Tr8n.SDK.Proxy.debug();"},

        "Alt+Shift+C"   =>  {"description"=>"Displays Tr8n credits", "script"=>"window.location = Tr8n.host + '/tr8n/help/credits';"},
        "Alt+Shift+D"   =>  {"description"=>"Opens dashboard", "script"=>"window.location = Tr8n.host + '/tr8n/translator/dashboard';"},
        "Alt+Shift+M"   =>  {"description"=>"Opens sitemap", "script"=>"window.location = Tr8n.host + '/tr8n/app/sitemap';"},
        "Alt+Shift+P"   =>  {"description"=>"Opens phrases", "script"=>"window.location = Tr8n.host + '/tr8n/app/phrases';"},
        "Alt+Shift+T"   =>  {"description"=>"Opens translations", "script"=>"window.location = Tr8n.host + '/tr8n/app/translations';"},
        "Alt+Shift+A"   =>  {"description"=>"Opens awards", "script"=>"window.location = Tr8n.host + '/tr8n/app/awards';"},
        "Alt+Shift+B"   =>  {"description"=>"Opens message board", "script"=>"window.location = Tr8n.host + '/tr8n/app/forum';"},
        "Alt+Shift+G"   =>  {"description"=>"Opens glossary", "script"=>"window.location = Tr8n.host + '/tr8n/app/glossary';"},
        "Alt+Shift+H"   =>  {"description"=>"Opens help", "script"=>"window.location = Tr8n.host + '/tr8n/help';"}
    }
  end

  def shortcuts
    self.definition ||= {}
    unless definition["shortcuts"]
      definition["shortcuts"] = default_shortcuts
      save
    end
    definition["shortcuts"]
  end

  def default_feature
    {
      "javascript_sdk" => {"description" => "JavaScript SDK", "enabled" => false},
      "google_suggestions" => {"description" => "Google Translation Suggestions", "enabled" => false},
      "shortcuts" => {"description" => "Keyboard Shortcuts", "enabled" => true},
      "decorations" => {"description" => "Custom Decorations", "enabled" => true},
      "glossary" => {"description" => "Application Glossary", "enabled" => true},
      "forum" => {"description" => "Translator Forum", "enabled" => true},
      "awards" => {"description" => "Awards", "enabled" => true},
    }
  end

  def features
    self.definition ||= {}
    definition["features"] ||= {}

    @features ||= begin
      feats = default_feature.clone
      feats.each do |key, data|
        next unless definition["features"][key]
        feats[key]["enabled"] = definition["features"][key]["enabled"]
      end

      feats
    end
  end

  def toggle_feature(key, flag)
    self.definition ||= {}
    definition["features"] ||= {}
    definition["features"][key.to_s] ||= {}
    definition["features"][key.to_s]["enabled"] = flag
    save

    definition["features"][key.to_s]["enabled"]
  end

  def feature_enabled?(key)
    features[key.to_s]["enabled"]
  end

  def shortcuts_enabled?
    self.definition ||= {}
    definition["shortcuts_enabled"].nil? ? true : definition["shortcuts_enabled"]
  end

  def javascript_sdk_enabled?
    self.definition ||= {}
    definition["javascript_sdk_enabled"].nil? ? false : definition["javascript_sdk_enabled"]
  end

  def google_suggestions_enabled?
    self.definition ||= {}
    definition["google_suggestions_enabled"].nil? ? true : definition["google_suggestions_enabled"]
  end

  def to_api_hash(opts = {})
    hash = {
        :key => self.key,
        :name => self.name,
        :description => self.description,
    }

    if opts[:definition]
      defs = {}
      defs.merge!({
                      :default_data_tokens        => Tr8n::Config.default_data_tokens,
                      :default_decoration_tokens  =>  Tr8n::Config.default_decoration_tokens,
                      :enable_language_cases      => Tr8n::Config.config[:enable_language_cases],
                      :enable_language_flags      => Tr8n::Config.config[:enable_language_flags],
                  })

      defs[:rules] = {}
      Tr8n::Config.language_rule_classes.each do |rule_class|
        defs[:rules][rule_class.keyword] = rule_class.config
      end

      hash[:definition] = defs
      hash[:languages] = languages.collect{|l| l.to_api_hash(opts)}
      hash[:sources] = sources.collect{|s| s.to_api_hash(opts)}
      hash[:components] = components.collect{|c| c.to_api_hash(opts)}

      hash[:styles] = classes
    end

    hash
  end

protected

  def generate_keys
    self.key = Tr8n::Config.guid if key.nil?
    self.secret = Tr8n::Config.guid if secret.nil?
  end

end
