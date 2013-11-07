#--
# Copyright (c) 2010-2013 Michael Berkovich, tr8nhub.com
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
  class Initializer

    def self.root
      Rails.root
    end

    def self.env
      Rails.env
    end

    def self.models
      @models ||= begin
        files = Dir[File.expand_path("../../../app/models/tr8n/**/*.rb", __FILE__)]

        mods = []
        files.sort.each do |file|
          class_name = file[file.rindex('tr8n')..-1].gsub('.rb', '').camelcase
          mods << class_name.constantize
        end

        mods
      end
    end

    # will clean all tables and initialize default values
    # never ever do it on live !!!
    def self.init
      #raise "This action is prohibited in this environment" if ['production', 'stage', 'staging'].include?(env)

      log "Resetting tr8n tables..."

      models.each do |cls|
        log ">> Resetting #{cls.name}..."
        cls.delete_all
      end
      log "Done."

      init_countries
      init_languages
      init_language_flags
      init_container_application
      init_glossary
      init_emails

      log "Done."
    end

    def self.init_countries
      log "Initializing countries..."
      countries_file = File.expand_path(File.join(data_path, "countries", "countries.json"))
      flags_folder = File.expand_path(File.join(data_path, "countries", "flags"))

      json = load_json(countries_file)
      json.each do |code, name|
        log ">> Importing #{name}..."
        country = Tr8n::Country.create(:code => code.downcase, :english_name => name)
        flag_path = "#{flags_folder}/#{name}.png"
        if File.exists?(flag_path)
          Tr8n::Media::LanguageFlag.create_from_file(country, name, File.read(flag_path))
        end
      end
      log "Created #{Tr8n::Country.count} countries."
    end


    def self.init_container_application
      log "Initializing container application..."

      app = Tr8n::Application.find_by_key("default") || Tr8n::Application.create(:key => "default", :name => "Tr8n Translation Service", :default_language => Tr8n::Language.by_locale("en-US"))

      # setup for base url
      [Tr8n::Config.base_url, "http://localhost", "http://127.0.0.1"].each do |url|
        uri = URI.parse(url)
        domain = Tr8n::TranslationDomain.find_by_name(uri.host) || Tr8n::TranslationDomain.create(:name => uri.host)
        domain.application = app
        domain.save
      end

      ["en-US", "et", "sv", "es", "fr", "he", "no", "da", "nl", "de", "ru"].each do |locale|
        l = Tr8n::Language.by_locale(locale)
        app.add_language(l) if l
      end

      app
    end

    def self.import_language(files, locale)
      unless files[locale]
        return Tr8n::Language.by_locale(locale)
      end

      json = load_json(files[locale])

      log ">> Initializing #{json["english_name"]}..."

      if json["fallback"]
        fallback_json = load_json(files[json["fallback"]])
        json = fallback_json.rmerge(json)
        # json["fallback_language"] = import_language(files, json["fallback"])
      end

      language = Tr8n::Language.create_from_json(json)

      #files[locale]= nil

      language
    end

    def self.data_path
      File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "data"))
    end

    def self.init_languages
      log "Initializing languages..."

      folder = File.expand_path(File.join(data_path, "languages"))

      language_files = {}

      Dir[File.join(folder, "*.json")].each do |file|
        locale = File.basename(file, ".json")
        language_files[locale] = file
      end

      locales = language_files.keys
      locales.sort.each do |locale|
        next unless language_files[locale] # has already been added
        lang = import_language(language_files, locale)
      end

      log "Created #{Tr8n::Language.count} languages."
    end

    def self.init_language_flags
      log "Initializing language flags..."

      folder = File.expand_path(File.join(data_path, "languages", "flags"))
      updated_locales = []
      Dir[File.join(folder, "*.png")].each do |file|
        locale = File.basename(file, ".png")
        lang = Tr8n::Language.by_locale(locale)
        unless lang
          log("#{locale} does not exist, yet the flag is there. Skipping...")
          next
        end
        if lang.flag
          log("#{locale} already has a flag. Skipping...")
          updated_locales << locale
          next
        end

        Tr8n::Media::LanguageFlag.create_from_file(lang, locale, File.read(file))

        updated_locales << locale
      end

      missing_flags = Tr8n::Language.where("locale not in (?)", updated_locales).collect{|l| l.locale}
      log("The following languages are missing flags: #{missing_flags.join(", ")}")
    end

    def self.init_glossary
      log "Initializing default glossary..."

      glossary_file = File.expand_path(File.join(data_path, "container_application", "glossary.yml"))
      glossary = load_yml(glossary_file)

      glossary.each do |keyword, description|
        Tr8n::Glossary.create(:keyword => keyword, :description => description)
      end
    end

    def self.init_emails
      log "Initializing default emails..."

      Tr8n::Emails::Template.delete_all
      Tr8n::Emails::Partial.delete_all
      Tr8n::Emails::Layout.delete_all
      Tr8n::Emails::Asset.delete_all

      folder = File.expand_path(File.join(data_path, "container_application", "emails"))
      Dir[File.join(folder, "templates", "*.json")].each do |file|
        json = load_json(file)
        language = Tr8n::Language.by_locale(json.delete(:locale)) if json[:locale]
        log "Importing template #{json[:keyword]}..."
        Tr8n::Emails::Template.create(json.merge(:application => Tr8n::RequestContext.container_application, :language => language))
      end

      Dir[File.join(folder, "partials", "*.json")].each do |file|
        json = load_json(file)
        language = Tr8n::Language.by_locale(json.delete(:locale)) if json[:locale]
        log "Importing partial #{json[:keyword]}..."
        Tr8n::Emails::Partial.create(json.merge(:application => Tr8n::RequestContext.container_application, :language => language))
      end

      Dir[File.join(folder, "layouts", "*.json")].each do |file|
        json = load_json(file)
        language = Tr8n::Language.by_locale(json.delete(:locale)) if json[:locale]
        log "Importing layout #{json[:keyword]}..."
        Tr8n::Emails::Layout.create(json.merge(:application => Tr8n::RequestContext.container_application, :language => language))
      end

      Dir[File.join(folder, "assets", "*.*")].each do |file|
        log "Importing asset #{file}..."
        name = file.split(File::SEPARATOR).last
        ext = name.split('.').last
        next unless ['jpg', 'png', 'gif'].include?(ext)
        Tr8n::Emails::Asset.create_from_file(Tr8n::RequestContext.container_application, name.gsub(".#{ext}", ""), File.read(file))
      end

    end

    # json support
    def self.load_json(file_path)
      json = JSON.parse(File.read(file_path))
      return HashWithIndifferentAccess.new(json) if json.is_a?(Hash)
      map = {"map" => json}
      HashWithIndifferentAccess.new(map)[:map]
    end

    def self.load_yml(file_path)
      yml = YAML.load_file(file_path)
      HashWithIndifferentAccess.new(yml)
    end

    def self.log(msg)
      puts msg
    end
  end
end
