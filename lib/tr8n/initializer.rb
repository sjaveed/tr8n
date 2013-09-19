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

      puts "Resetting tr8n tables..."

      models.each do |cls|
        puts ">> Resetting #{cls.name}..."
        cls.delete_all
      end
      puts "Done."

      init_countries
      init_languages
      init_glossary
      init_container_application

      puts "Done."
    end

    def self.init_countries
      puts "Initializing countries..."
      countries_file = File.expand_path(File.join(data_path, "countries.json"))
      json = load_json(countries_file)
      json.each do |code, name|
        puts ">> Importing #{name}..."
        Tr8n::Country.create(:code => code.downcase, :english_name => name)
      end
      puts "Created #{Tr8n::Country.count} countries."
    end


    def self.init_container_application
      puts "Initializing container application..."

      app = Tr8n::Application.find_by_key("default") || Tr8n::Application.create(:key => "default", :name => Tr8n::Config.site_title, :default_language => Tr8n::Language.by_locale("en-US"))

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

      puts ">> Initializing #{json["english_name"]}..."

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
      puts "Initializing languages..."

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

      puts "Created #{Tr8n::Language.count} languages."
    end

    def self.init_glossary
      puts "Initializing default glossary..."

      glossary_file = File.expand_path(File.join(data_path, "container_application", "glossary.yml"))
      glossary = load_yml(glossary_file)

      glossary.each do |keyword, description|
        Tr8n::Glossary.create(:keyword => keyword, :description => description)
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

  end
end
