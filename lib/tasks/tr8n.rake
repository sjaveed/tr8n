#--
# Copyright (c) 2010-2012 Michael Berkovich, tr8n.net
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

namespace :tr8n do
  desc "Initializes all of the tables with default data"
  task :init => :environment do
    Tr8n::Initializer.init
  end

  desc "Export languages"
  task :export_languages => :environment do
    path = ENV['path'] || 'config/tr8n/languages'
    FileUtils.mkdir_p(path)

    proc = Proc.new { |k, v| v.kind_of?(Hash) ? (v.delete_if(&proc); nil) : (v.nil? or (v.is_a?(String) and v.blank?) or (v === false)) }

    Tr8n::Language.all.each do |lang|
      pp "Exporting #{lang.locale}..."
      file_path = path + "/" + lang.locale + ".json"
      File.open(file_path, 'w') do |file|
        json = lang.to_api_hash(:definition => true)
        json.delete_if(&proc)
        file.write(JSON.pretty_generate(json))
      end
    end
  end

  desc "Resets all metrics"
  task :reset_metrics => :environment do
    Tr8n::LanguageMetric.reset_metrics
  end

  desc "Calculates metrics"
  task :metrics => :environment do
    Tr8n::LanguageMetric.calculate_language_metrics
  end

  desc "Initializes default settings cases"
  task :cases => :environment do
    Tr8n::Language.all.each do |lang|
      lang.reset_language_cases!
    end 
  end

  desc "Creates featured languages"
  task :featured_languages => :environment do
    Tr8n::Config.config[:featured_languages].each_with_index do |locale, index|
      lang = Tr8n::Language.by_locale(locale)
      lang.featured_index = 10000 - (index * 100)
      lang.save
    end
  end

  desc "Exports default email configuration"
  task :export_emails => :environment do
    base_path = File.expand_path("#{__FILE__}/../../../config/data/container_application/emails")
    proc = Proc.new { |k, v| v.kind_of?(Hash) ? (v.delete_if(&proc); nil) : (v.nil? or (v.is_a?(String) and v.blank?) or (v === false)) }

    Tr8n::RequestContext.container_application.email_templates.each do |et|
       pp "Exporting template #{et.keyword}..."
       file_path = base_path + "/templates/" + et.keyword + ".json"
       File.open(file_path, 'w') do |file|
         json = et.to_api_hash(:definition => true)
         json.delete_if(&proc)
         file.write(JSON.pretty_generate(json))
       end
    end

    Tr8n::RequestContext.container_application.email_partials.each do |et|
      pp "Exporting partial #{et.keyword}..."
      file_path = base_path + "/partials/" + et.keyword + ".json"
      File.open(file_path, 'w') do |file|
        json = et.to_api_hash(:definition => true)
        json.delete_if(&proc)
        file.write(JSON.pretty_generate(json))
      end
    end

    Tr8n::RequestContext.container_application.email_layouts.each do |et|
      pp "Exporting layout #{et.keyword}..."
      file_path = base_path + "/layouts/" + et.keyword + ".json"
      File.open(file_path, 'w') do |file|
        json = et.to_api_hash(:definition => true)
        json.delete_if(&proc)
        file.write(JSON.pretty_generate(json))
      end
    end

    Tr8n::RequestContext.container_application.email_assets.each do |et|
      pp "Copying asset #{et.keyword}..."
      file_path = base_path + "/assets/" + et.export_file_name
      FileUtils.cp(et.full_path, file_path)
    end

    pp "Done."
  end

  desc "Import default email configuration"
  task :import_emails => :environment do
     Tr8n::Initializer.init_emails
  end

  # will delete all keys that have not been verified in the last 2 weeks
  task :delete_unverified_keys => :environment do
    date = env('before') || (Date.today - 2.weeks)
    
    puts "Running key destruction process..."
    t0 = Time.now
    
    puts "All keys not verified after #{date} will be destroyed!"
    unverified_keys = Tr8n::TranslationKey.find(:all, :conditions => ["verified_at is null or verified_at < ?", date])
    
    puts "There are #{unverified_keys.size} keys to be destroyed."
    puts "Destroying unverified keys..." if unverified_keys.size > 0

    destroy_count = 0
    unverified_keys.each do |tkey|
      tkey.destroy
      destroy_count += 1
      puts "Destroyed #{destroy_count} keys..." if destroy_count % 100 == 0
    end
    
    t1 = Time.now
  
    puts "Destroyed #{destroy_count} keys"
    puts "Destruction process took #{t1-t0} mls"
  end
  
  desc 'Update IP to Location table (file=<file|config/tr8n/data/ip_locations.csv>)'
  task :import_ip_locations => :environment do
    Tr8n::IpLocation.import_from_file('config/tr8n/data/ip_locations.csv', :verbose => true)
  end
  
  desc "Synchronize translations with tr8n.net"
  task :sync => :environment do
    opts = {}
    opts[:force] = true if ENV["force"] == "true"
    Tr8n::SyncLog.sync(opts)
  end

  desc "import keys"
  task :import_keys  => :environment do
    path = ENV['source']
    dry_run = (ENV['dry'] == "true")
    start_at = (ENV['start_at'] || 0).to_i
    clear = (ENV['clear'] == "true")
    only_category = ENV['category']

    by_locale = {}
    by_category = {}

    Thread.current[:tr8n_block_options] ||= []
    Thread.current[:tr8n_block_options].push({:skip_cache => true})

    puts "Building indexes..."

    file_count = 0
    Dir[File.join(path, "*.json")].each do |file_name|
      locale, category = File.basename(file_name, '.json').split('_')
      by_locale[locale] ||= []
      by_locale[locale] << category

      by_category[category] ||= []
      by_category[category] << locale

      print "."
      file_count += 1
    end

    puts "\n"
    puts "Validating English keys..."
    by_category.keys.each do |cat|
      unless by_locale["EN"].include?(cat)
        puts "Category #{cat} is missing EN locale, but is has the following locales: #{by_category[cat]}"
      end
    end

    puts "\n"
    puts "Validating missing locales..."
    by_category.each do |cat, locales|
      unless by_locale.keys.sort == locales.sort
        puts "Category #{cat} is missing locales: #{by_locale.keys - locales}"
      end
    end

    puts "\n"
    puts "Mapping Tr8n languages..."

    puts "MyHeritage locales: #{by_locale.keys}"

    puts "Geni locale mapping:"
    Tr8n::Language.where("myheritage_key is not null").each do |l|
      puts "Geni #{l.english_name}: #{l.locale} => MyHeritage: #{l.myheritage_key}"
    end

    puts "\n"
    tr8n_languages = {}
    by_locale.keys.each do |locale|
      lang = Tr8n::Language.where("myheritage_key = ?", locale).first
      tr8n_languages[locale] = lang
      unless lang
        puts "Language for locale #{locale} does not exist in Tr8n..."
      end
    end

    if clear
      puts "\n"
      puts "Cleaning up database...."
      [Tr8n::TranslationKey,Tr8n::Translation, Tr8n::TranslationSource, Tr8n::TranslationKeySource].each do |klass|
        puts "Clearing records for #{klass.name}..."
        klass.delete_all
      end
    end

    puts "\n"
    puts "Importing keys...."

    key_count = 0
    trans_count = 0

    t0 = Time.now

    application = Tr8n::RequestContext.container_application
    by_locale["EN"].each_with_index do |cat, index|
      next if start_at > index

      unless only_category.blank?
        next if cat != only_category
      end

      tt0 = Time.now

      file_name = "#{path}/EN_#{cat}.json"
      file = File.read(file_name)
      data = JSON.parse(file)

      next unless data.is_a?(Hash)

      puts "\n"
      puts "Importing #{cat} : #{data.keys.size} keys :  #{index+1} out of #{by_locale["EN"].size} : #{((index+1) * 100.0 /by_locale["EN"].size).to_i}% complete..."
      puts "------------------------------------------------------------------------------------------"
      puts "Importing #{cat} : EN..."

      keys = {}

      unless dry_run
        source = Tr8n::TranslationSource.where("application_id = ? and source = ?", application.id, cat).first
        source ||= Tr8n::TranslationSource.create(:application_id => application.id, :source => cat)
      end

      data.each do |key, label|

        if label.blank?
          #pp "Key label is blank, next ..."
          #keys[key] = existing_key
          next
        end

        #puts "Importing: #{key} #{label} ..."
        tr8n_key = Tr8n::TranslationKey.generate_key(label, cat).to_s
        #puts "[#{tr8n_key}]"

        existing_key = Tr8n::TranslationKey.where("key = ?", tr8n_key).first unless dry_run
        if existing_key
          #pp "Found existing key: ", existing_key.label
          keys[key] = existing_key
          next
        end

        unless dry_run
          keys[key] = Tr8n::TranslationKey.create( :key         => tr8n_key,
                                                   :label       => label,
                                                   :description => cat,
                                                   :locale      => 'en-US')

          Tr8n::TranslationKeySource.create(:translation_key => keys[key], :translation_source => source)
        end

        key_count += 1
      end

      by_category[cat].each do |locale|
        next if locale == 'EN'

        file_name = "#{path}/#{locale}_#{cat}.json"
        unless File.exist?(file_name)
          puts "#{file_name} does not exist, next..."
          next
        end

        lang = tr8n_languages[locale]
        unless lang
          puts "#{locale} does not exist in Geni, next..."
          next
        end

        puts "Importing #{cat} : #{locale}..."

        file = File.read(file_name)
        data = JSON.parse(file)

        data.each do |key, label|
          unless dry_run
            tkey = keys[key]

            unless tkey
              #puts "#{keys[key].label} was never defined in English, next..."
              next
            end

            if tkey.translations.where("language_id = ?", lang.id).count > 0
              #puts "#{keys[key].label} has already been imported, next..."
              next
            end

            if label.blank?
              #puts "Translation for #{keys[key].label} is blank, next..."
              next
            end

            Tr8n::Translation.create(:translation_key => tkey, :language => lang, :translator => Tr8n::Config.system_translator, :label => label)
          end

          trans_count += 1
        end
      end

      tt1 = Time.now
      puts "Importing #{cat} took: #{tt1-tt0}"
      puts "\n"
    end

    t1 = Time.now

    puts "\n"
    puts "Imported #{key_count} keys with #{trans_count} translations from #{file_count} files in #{by_locale.keys.count} locales"
    puts "Running time: #{t1-t0}"
  end

  desc "fix languages"
  task :langs => :environment do
    backup = false

    path = File.expand_path("../../../config/data/languages", __FILE__)

    if backup
      backup_path = File.expand_path("../../../../../../languages_backups/#{Time.now.to_i.to_s}", __FILE__)
      pp "Backing up to #{backup_path}..."
      FileUtils.mkdir_p(backup_path)
      FileUtils.cp_r(Dir.glob("#{path}/*"), backup_path)
    end

    #mapping = JSON.parse(File.read(File.expand_path("../../../config/data/mapping.json", __FILE__)))
    #mhmap = {}
    #mapping.each do |data|
    #  mhmap[data["locale"]] = data["google_key"]
    #end

    count = 0
    Dir[File.join(path, "*.json")].each do |file_name|
      print " . "
      file = File.read(file_name)
      begin
        data = JSON.parse(file)

        next unless data["context_rules"]

        print data["locale"]

        count += 1

        data["context_rules"].each do |ckey, info|
          next unless info["rules"]
          info["rules"].each do |rkey, rule|
            next unless rule["rule"]
            pp [ckey, rkey, rule["rule"]]

            pp Tr8n::RulesEngine::Parser.new(rule["rule"]).parse
          end
        end

        next

        #File.open(file_name, 'w') { |file| file.write(JSON.pretty_generate(data)) }
      rescue Exception => ex
        pp ""
        raise ex
      end
    end

    pp "", ""
    pp "Processed #{count} languages"

  end


end