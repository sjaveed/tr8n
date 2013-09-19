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







  def stuff
    #if file.index("mod 10 @n")
    #  count += 1
    #  file = file.gsub("mod 10 @n", "mod @n 10")
    #end

    #data["context_rules"]["list"] = {
    #  "keys"=> [
    #    "one",
    #    "other"
    #  ],
    #  "token_expression"=> "/.*(items|list)(\\d)*$/",
    #  "variables"=> [
    #    "@count"
    #  ],
    #  "token_mapping"=> [
    #    "unsupported",
    #    {
    #      "one"=> "{$0}",
    #      "other"=> "{$1}"
    #    }
    #  ],
    #  "default_rule"=> "other",
    #  "rules"=> {
    #    "one"=> {
    #      "rule"=> "(= 1 @count)",
    #      "description"=> "{token} contains 1 element"
    #    },
    #    "other"=> {
    #      "description"=> "{token} contains at least 2 elements"
    #    }
    #  }
    #}

    if data["context_rules"] and data["context_rules"]["number"]
      if data["context_rules"]["number"]["keys"] == ["other"]
        data["context_rules"]["number"]["token_mapping"] = "unsupported"
        count += 1
      end
    end

    data["context_rules"]["number"] = {
        "keys"=> ["one", "other"],
        "token_expression"=>  "/.*(count|num|minutes|seconds|hours)(\d)*$/",
        "variables"=> ["@n"],
        "token_mapping"=> ["unsupported", {"one"=> "{$0}", "other"=> "{$1}"}],
        "default_rule"=> "other",
        "rules"=> {
            "one"=>    {"rule"=> "(= 1 @n)", "description"=> "{token} is 1", "examples"=> "1"},
            "other"=>  {"description"=> "{token} is not 1", "examples"=> "0, 2-999; 1.2, 2.07..."}
        }
    }    
    #if data["english_name"] and data["english_name"] == data["native_name"]
    #  print " = yep "
    #  data.delete("native_name")
    #end

    #if data["context_rules"] and data["context_rules"]["number"]
    #  data["context_rules"]["number"]["token_expression"] = "/.*(count|num|minutes|seconds|hours)(\\d)*$/"
    #  unless data["context_rules"]["number"]["variables"]
    #    data["context_rules"]["number"]["variables"] = ["@n"]
    #  end
    #
    #  unless data["context_rules"]["number"]["token_mapping"]
    #    data["context_rules"]["number"]["token_mapping"]  = ["unsupported", {"one" => "{$0}", "other" => "{$1}"}]
    #  end
    #
    #  unless data["context_rules"]["number"]["default_rule"]
    #    data["context_rules"]["number"]["default_rule"] = "other"
    #  end
    #end

    data["context_rules"]["date"] = {
        "keys" => [
            "past",
            "present",
            "future"
        ],
        "token_expression"=> "/.*(date|time)(\\d)*$/",
        "variables"=> ["@date"],
        "token_mapping"=> [
            "unsupported",
            "unsupported",
            {
                "past"=> "{$0}",
                "present"=> "{$1}",
                "future"=> "{$2}"
            }
        ],
        "default_rule"=> "present",
        "rules"=> {
            "past"=> {
                "rule"=> "(> @date (today))",
                "description"=> "{token} is in the future"
            },
            "present"=> {
                "rule"=> "(= @date (today))",
                "description"=> "{token} is in the present"
            },
            "future"=> {
                "rule"=> "(< @date (today))",
                "description"=> "{token} is in the past"
            }
        }
    }

    if data["context_rules"]["gender_list"]
      data["context_rules"].delete("gender_list")
    end

    data["context_rules"]["genders"] = {
        "keys"  => ["male", "female", "unknown", "other"],
        "token_expression"  =>  "/.*(users|profiles|actors|targets)(\\d)*$/",
        "variables" => ["@genders"],
        "token_mapping" => ["unsupported", "unsupported", "unsupported", {"male"=> "{$0}", "female"=>"{$1}", "unknown"=>"{$2}", "other"=>"{$3}"}],
        "default_rule"  => "other",
        "rules" => {
            "male"=> {"rule"=> "(&& (= 1 (count @genders)) (all @genders 'male'))", "description"=> "{token} contains 1 male"},
            "female"=> {"rule"=> "(&& (= 1 (count @genders)) (all @genders 'female'))", "description"=> "{token} contains 1 female"},
            "unknown"=> {"rule"=> "(&& (= 1 (count @genders)) (all @genders 'unknown'))", "description"=> "{token} contains 1 person with unknown gender"},
            "other"=> {"description"=> "{token} contains at least 2 people"}
        }
    }
    if data["context_rules"] and data["context_rules"]["gender"]
      unless data["context_rules"]["gender"]["keys"]
        data["context_rules"]["gender"]["keys"] = ["male", "female", "other"]
      end

      unless data["context_rules"]["gender"]["variables"]
        data["context_rules"]["gender"]["variables"] = ["@gender"]
      end

      unless data["context_rules"]["gender"]["token_expression"]
        data["context_rules"]["gender"]["token_expression"] = "/.*(user|translator|profile|actor|target)(\\d)*$/"
      end

      unless data["context_rules"]["gender"]["token_mapping"]
        data["context_rules"]["gender"]["token_mapping"] = [{"other" => "{$0}"},
                                                            {"male" => "{$0}", "female" => "{$1}", "other" => "{$0}/{$1}"},
                                                            {"male" => "{$0}", "female" => "{$1}", "other" => "{$2}"}]
      end

      unless data["context_rules"]["gender"]["default_rule"]
        data["context_rules"]["gender"]["default_rule"] = "other"
      end

      unless data["context_rules"]["gender"]["rules"]
        data["context_rules"]["gender"]["rules"] = {
            "male"    =>    {"rule"=> "(= 'male' @gender)", "description"=> "{token} is a male"},
            "female"  =>    {"rule"=> "(= 'female' @gender)", "description"=> "{token} is a female"},
            "other"   =>    {"description"=> "{token}'s gender is unknown"}
        }

        count += 1
      end
    end
  end

end