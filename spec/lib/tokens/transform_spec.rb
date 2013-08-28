require File.expand_path('../../spec_helper', File.dirname(__FILE__))

describe Tr8n::Tokens::Transform do
  describe 'registering transform tokens' do

    context 'incorrect tokens' do
      it 'should not be registered' do
        [
          'Hello {user}',
          'Hello {user:}',
          'Hello {user::}'
        ].each do |label|
          Tr8n::Tokens::Transform.parse(label).should be_empty
        end
      end
    end

    context 'correct tokens' do
      it 'should register them all ' do
        [
          '{user:gender|his,her}',
          '{user:gender| male: his, female: her}',
          '{count:number|message}',
          '{count:number|message, messages}',
          '{count:number| one: message, other: messages}',
          '{count:number||message}',
          '{count:number|| one: message, other: messages}',
          'Dear {user:gender}, you have {count:number||message}',
          'Dear {user:gender}, you have {count:number|| one: message, other: messages}',
          '{count | message}',
          '{count | message, messages}',
          '{count:number | message, messages}',
          '{user:gender | he, she, he/she}',
          '{now:date | did, does, will do}',
          '{users:list | all male, all female, mixed genders}',
          '{count || message, messages}'
        ].each do |label|
          tokens = Tr8n::Tokens::Transform.parse(label)
          tokens.count.should eq(1)
          tokens.first.class.name.should eq("Tr8n::Tokens::Transform")
        end

        [
          '{user:gender|He, She} received {count:number||message}',
          '{user:gender | male: He, female: She } received {count:number || message, messages }'
        ].each do |label|
          tokens = Tr8n::Tokens::Transform.parse(label)
          tokens.count.should eq(2)
          tokens.first.class.name.should eq("Tr8n::Tokens::Transform")
        end

        label = '{user:gender | male: He, female: She }'
        tokens = Tr8n::Tokens::Transform.parse(label)
        tokens.first.class.name.should eq("Tr8n::Tokens::Transform")
        tokens.first.pipe_separator.should eq('|')
        tokens.first.piped_params.should eq(["male: He", "female: She"])
        tokens.first.context_keys.should eq(['gender'])
        tokens.first.case_keys.should eq([])

      end
    end

  end

  describe 'default transform tokens' do
    context 'using gender token mapping in the context' do
      it "should use correct value" do
        english = Tr8n::Language.create!(:locale => "en-US", :english_name => "English")

        context = Tr8n::LanguageContext.create(
            :language   =>     english,
            :keyword    =>     "gender",
            :definition =>   {
                "token_expression"  => '/.*(profile|user)(\d)*$/',
                "variables"         => ['@gender'],
                "token_mapping"     => [{"other" => "{$0}"}, {"male" => "{$0}", "female" => "{$1}", "other" => "{$0}/{$1}"}],
                "default_rule"      => "other"
            },
            :description =>    "Gender language context"
        )
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "male", :definition => "(= 'male' @gender)")
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "female", :definition => "(= 'female' @gender)")
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "other")

        token = Tr8n::Tokens::Transform.parse('{user:gender | male: He, female: She }').first
        token.piped_params.should eq(["male: He", "female: She"])
        token.generate_value_map(token.piped_params, context).should eq({"male"=>"He", "female"=>"She"})

        token = Tr8n::Tokens::Transform.parse('{user| male: He, female: She }').first
        token.piped_params.should eq(["male: He", "female: She"])
        token.generate_value_map(token.piped_params, context).should eq({"male"=>"He", "female"=>"She"})

        token = Tr8n::Tokens::Transform.parse('{user:gender | He, She }').first
        token.piped_params.should eq(["He", "She"])
        token.generate_value_map(token.piped_params, context).should eq({"male"=>"He", "female"=>"She", "other"=>"He/She"})

        token = Tr8n::Tokens::Transform.parse('{user | He, She }').first
        token.piped_params.should eq(["He", "She"])
        token.generate_value_map(token.piped_params, context).should eq({"male"=>"He", "female"=>"She", "other"=>"He/She"})

        token = Tr8n::Tokens::Transform.parse('{user:gender | Born on}').first
        token.piped_params.should eq(["Born on"])
        token.generate_value_map(token.piped_params, context).should eq({"other"=>"Born on"})

        token = Tr8n::Tokens::Transform.parse('{user | Born on}').first
        token.piped_params.should eq(["Born on"])
        token.generate_value_map(token.piped_params, context).should eq({"other"=>"Born on"})
      end
    end

    context 'using gender token mapping in the context' do
      it "should use correct value" do
        english = Tr8n::Language.create!(:locale => "en-US", :english_name => "English")

        context = Tr8n::LanguageContext.create(
            :language   =>     english,
            :keyword    =>     "number",
            :definition =>   {
                "token_expression"  => '/.*(num)(\d)*$/',
                "variables"         => ['@number'],
                "token_mapping"     => [{"one" => "{$0}", "other" => "{$0::plural}"}, {"one" => "{$0}", "other" => "{$1}"}],
                "default_rule"      => "other"
            },
            :description =>    "Number language context"
        )
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "one", :definition => "(= 1 @n)")
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "other")

        plural_case = Tr8n::LanguageCase.create(
            language:     english,
            keyword:      "plural",
            latin_name:   "Plural",
            native_name:  "Plural",
            description:  "Converts singular value to plural value",
            application:  "phrase")

        plural_case.add_rule(0, {"conditions" => "(= 'message' @value)", "operations" => "(quote 'messages')"})

        token = Tr8n::Tokens::Transform.parse('{num|| one: message, other: messages}').first
        token.piped_params.should eq(["one: message", "other: messages"])
        token.generate_value_map(token.piped_params, context).should eq({"one"=>"message", "other" => "messages"})

        token = Tr8n::Tokens::Transform.parse('{num|| message}').first
        token.piped_params.should eq(["message"])
        token.generate_value_map(token.piped_params, context).should eq({"one"=>"message", "other" => "messages"})
      end
    end
  end

end
