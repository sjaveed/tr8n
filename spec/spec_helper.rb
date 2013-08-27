ENV["RAILS_ENV"] = "test"

require 'pp'
require 'spork'

def fixtures_root
  File.join(File.dirname(__FILE__), 'fixtures')
end

def load_json(file_path)
  JSON.parse(File.read("#{fixtures_root}/#{file_path}"))
end

def stub_user(attrs)
  user = double()
  attrs.each do |key, value|
    user.stub(key) { value }
  end
  user
end

def setup_english_language
  english = Tr8n::Language.create!(:locale => "en-US", :english_name => "English")

  context = Tr8n::LanguageContext.create(
      language:     english,
      keyword:      "gender",
      definition:   {
          "token_expression"  => '/.*(profile|user)(\d)*$/',
          "variables"         => ['@gender'],
          "token_mapping"     => {"male" => "{$0}", "female" => "{$1}", "unknown" => "{$0}/{$1}"}
      },
      description:   "Gender language context"
  )
  Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "male", :definition => "(= 'male' @gender)")
  Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "female", :definition => "(= 'female' @gender)")
  Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "other")

  context = Tr8n::LanguageContext.create(
      language:     english,
      keyword:      "number",
      definition:   {
          "token_expression"  => '/.*(num|count)(\d)*$/',
          "variables"         => ['@n'],
          "token_mapping"     => {"one" => "{$0}", "other" => "{$0::plural}"}
      },
      description:   "Number language context"
  )
  Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "male", :definition => "(= 1 @n)")
  Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "other")

  plural_case = Tr8n::LanguageCase.create(
      language:     english,
      keyword:      "plural",
      latin_name:   "Plural",
      native_name:  "Plural",
      description:  "Converts singular value to plural value",
      application:  "phrase")

  position = 0
  uncounatable = ['sheep', 'fish', 'series', 'species', 'money', 'rice', 'information', 'equipment']
  plural_case.add_rule(position, {"conditions" => "(in '#{uncounatable.join(',')}' @value)", "operations" => "@value"})
  position += 1
  irregular = {
      'move'    =>  'moves',
      'sex'     =>  'sexes',
      'child'   =>  'children',
      'man'     =>  'men',
      'person'  =>  'people'
  }
  irregular.each do |search, replace|
    plural_case.add_rule(position, {"conditions" => "(= '#{search}' @value)", "operations" => "(quote '#{replace}')"})
    position += 1
  end
  plural = {
      '/(quiz)$/i'              => "$1zes",
      '/^(ox)$/i'                => "$1en",
      '/([m|l])ouse$/i'          => "$1ice",
      '/(matr|vert|ind)ix|ex$/i' => "$1ices",
      '/(x|ch|ss|sh)$/i'         => "$1es",
      '/([^aeiouy]|qu)y$/i'      => "$1ies",
      '/([^aeiouy]|qu)ies$/i'    => "$1y",
      '/(hive)$/i'               => "$1s",
      '/(?:([^f])fe|([lr])f)$/i' => "$1$2ves",
      '/sis$/i'                  => "ses",
      '/([ti])um$/i'             => "$1a",
      '/(buffal|tomat|potat)o$/i'=> "$1oes",
      '/(bu)s$/i'                => "$1ses",
      '/(alias|status)$/i'       => "$1es",
      '/(octop)us$/i'            => "$1i",
      '/(ax|test)is$/i'          => "$1es",
      '/us$/i'                   => "$1es",
      '/s$/i'                    => "s",
      '/$/'                      => "s"
  }
  plural.each do |search, replace|
    plural_case.add_rule(position, {"conditions" => "(match '#{search}' @value)", "operations" => "(replace '#{search}' '#{replace}' @value)"})
    position += 1
  end

  english
end

def setup_russian_language
  russian = Tr8n::Language.create!(:locale => "ru", :english_name => "Russian")

  context = Tr8n::LanguageContext.create(
      language:     russian,
      keyword:      "gender",
      definition:   {
          "rules"             => ["male", "female", "other"],
          "token_expression"  => '/.*(profile|user)(\d)*$/',
          "variables"         => ['@gender'],
          "token_mapping"     => {"male" => "{$0}", "female" => "{$1}", "unknown" => "{$0}/{$1}"}
      },
      description:   "Gender language context"
  )
  Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "male", :definition => "(= 'male' @gender)")
  Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "female", :definition => "(= 'female' @gender)")
  Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "other")

  context = Tr8n::LanguageContext.create(
      language:     russian,
      keyword:      "number",
      definition:   {
          "rules"             => ["one", "few", "many", "other"],
          "token_expression"  => '/.*(num|count)(\d)*$/',
          "variables"         => ['@n'],
          "token_mapping"     => {"one" => "{$0}", "few" => "{$1}", "other" => "{$2}"}
      },
      description:   "Number language context"
  )
  Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "one", :definition => "(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))")
  Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "few", :definition => "(&& (in '2..4' (mod @n 10)) (not (in '12..14' (mod @n 100))))")
  Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "many", :definition => "(|| (= 0 (mod @n 10)) (in '5..9' (mod @n 10)) (in '11..14' (mod @n 100)))")
  Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "other")

  russian
end

Spork.prefork do

	require File.expand_path("../../test/dummy/config/environment.rb",  __FILE__)
	require 'rspec/rails'

	ENGINE_RAILS_ROOT=File.join(File.dirname(__FILE__), '../')

	# Requires supporting ruby files with custom matchers and macros, etc,
	# in spec/support/ and its subdirectories.
	Dir[File.join(ENGINE_RAILS_ROOT, "spec/support/**/*.rb")].each {|f| require f }

	RSpec.configure do |config|
	  config.use_transactional_fixtures = true
      config.use_instantiated_fixtures  = false	  
	end

end


Spork.each_run do
  # This code will be run each time you run your specs.

end
