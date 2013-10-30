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

  desc "Import language flags"
  task :import_language_flags => :environment do
    Tr8n::Initializer.init_language_flags
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
    Tr8n::Logs::ExchangeSync.sync(opts)
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