require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe Tr8n::Translation do

  before :all do
    @user = User.create(:first_name => "Mike", :gender => "male")
    @translator = Tr8n::Translator.create(:name => "Mike", :user => @user, :gender => "male")
    @translation_key = Tr8n::TranslationKey.find_or_create("sample")

    @english = Tr8n::Language.create(:locale => "en-US", :english_name => "English")
    @russian = Tr8n::Language.create(:locale => "ru", :english_name => "Russian")
  end

  describe "context" do
    describe "with one token" do
      it "should match correct rules" do
        context = Tr8n::LanguageContext.create(
            language:     @russian,
            keyword:      "numeric",
            definition:   {
                "token_expression"  => '/.*(count|num|age|hours|minutes|years|seconds)(\d)*$/',
                "variables"         => ['@n']
            },
            description:   "Numeric language context"
        )

        Tr8n::Config.stub(:context_rules) {
          {
              "numeric" => {
                  "variables" => {
                      "@n" => "to_i",
                  }
              }
          }
        }

        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "one", :definition => "(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))", :description => "{n} mod 10 is 1 and {n} mod 100 is not 11", :examples => "1, 21, 31, 41, 51, 61...")
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "few", :definition => "(&& (in '2..4' (mod @n 10)) (not (in '12..14' (mod @n 100))))", :description => "{n} mod 10 in 2..4 and {n} mod 100 not in 12..14", :examples => "2-4, 22-24, 32-34...")
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "many", :definition => "(|| (= 0 (mod @n 10)) (in '5..9' (mod @n 10)) (in '11..14' (mod @n 100)))", :description => "{n} mod 10 is 0 or {n} mod 10 in 5..9 or {n} mod 100 in 11..14", :examples => "0, 5-20, 25-30, 35-40...")
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "other")


        one = Tr8n::Translation.create(:label => "You have one message", :context => {"count" => {"numeric" => "one"}}, :language => @russian, :translation_key => @translation_key, :translator => @translator)
        one.context.should eq({"count" => {"numeric" => "one"}})
        one.matches_rules?({"count" => 1}).should be_true
        one.matches_rules?({"count" => 2}).should be_false
        one.matches_rules?({"count" => 21}).should be_true
        one.matches_rules?({"count" => 11}).should be_false

        few = Tr8n::Translation.create(:label => "You have few messages", :context => {"count" => {"numeric" => "few"}}, :language => @russian, :translation_key => @translation_key, :translator => @translator)
        few.matches_rules?({"count" => 1}).should be_false
        few.matches_rules?({"count" => 2}).should be_true
        few.matches_rules?({"count" => 4}).should be_true
        few.matches_rules?({"count" => 5}).should be_false

        many = Tr8n::Translation.create(:label => "You have many messages", :context => {"count" => {"numeric" => "many"}}, :language => @russian, :translation_key => @translation_key, :translator => @translator)
        many.matches_rules?({"count" => 1}).should be_false
        many.matches_rules?({"count" => 2}).should be_false
        many.matches_rules?({"count" => 4}).should be_false
        many.matches_rules?({"count" => 5}).should be_true

        undefined = Tr8n::Translation.create(:label => "You have many messages", :context => {"count" => {"numeric" => "undefined"}}, :language => @russian, :translation_key => @translation_key, :translator => @translator)
        undefined.matches_rules?({"count" => 1}).should be_false

      end
    end

    describe "with multiple tokens" do
      it "should match correct rules" do
        context = Tr8n::LanguageContext.create(
            language:     @russian,
            keyword:      "numeric",
            definition:   {
                "token_expression"  => '/.*(count|num|age|hours|minutes|years|seconds)(\d)*$/',
                "variables"         => ['@n']
            },
            description:   "Numeric language context"
        )

        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "one", :definition => "(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))", :description => "{n} mod 10 is 1 and {n} mod 100 is not 11", :examples => "1, 21, 31, 41, 51, 61...")
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "few", :definition => "(&& (in '2..4' (mod @n 10)) (not (in '12..14' (mod @n 100))))", :description => "{n} mod 10 in 2..4 and {n} mod 100 not in 12..14", :examples => "2-4, 22-24, 32-34...")
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "many", :definition => "(|| (= 0 (mod @n 10)) (in '5..9' (mod @n 10)) (in '11..14' (mod @n 100)))", :description => "{n} mod 10 is 0 or {n} mod 10 in 5..9 or {n} mod 100 in 11..14", :examples => "0, 5-20, 25-30, 35-40...")
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "other")

        context = Tr8n::LanguageContext.create(
            language:     @russian,
            keyword:      "gender",
            definition:   {
                "token_expression"  => '/.*(user|profile)(\d)*$/',
                "variables"         => ['@gender']
            },
            description:   "Gender language context"
        )

        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "male", :definition => "(= 'male' @gender)")
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "female", :definition => "(= 'female' @gender)")
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "other")

        Tr8n::Config.stub(:context_rules) {
          {
              "numeric" => {
                  "variables" => {
                      "@n" => "to_i",
                  }
              },
              "gender" => {
                  "variables" => {
                      "@gender" => "gender",
                  }
              }
          }
        }

        one = Tr8n::Translation.create(:label => "Male got one message", :context => {"user" => {"gender" => "male"}, "count" => {"numeric" => "one"}}, :language => @russian, :translation_key => @translation_key, :translator => @translator)
        one.context.should eq({"user" => {"gender" => "male"}, "count" => {"numeric" => "one"}})
        one.matches_rules?({"user" => double(:gender => "male"), "count" => 1}).should be_true
        one.matches_rules?({"user" => double(:gender => "male"), "count" => 2}).should be_false
        one.matches_rules?({"user" => double(:gender => "male"), "count" => 21}).should be_true
        one.matches_rules?({"user" => double(:gender => "male"), "count" => 11}).should be_false
        one.matches_rules?({"user" => double(:gender => "female"), "count" => 1}).should be_false

        few = Tr8n::Translation.create(:label => "You have few messages", :context => {"user" => {"gender" => "female"}, "count" => {"numeric" => "few"}}, :language => @russian, :translation_key => @translation_key, :translator => @translator)
        few.matches_rules?({"user" => double(:gender => "male"), "count" => 1}).should be_false
        few.matches_rules?({"user" => double(:gender => "female"), "count" => 2}).should be_true
        few.matches_rules?({"user" => double(:gender => "female"), "count" => 4}).should be_true
        few.matches_rules?({"user" => double(:gender => "male"), "count" => 5}).should be_false
        few.matches_rules?({"user" => double(:gender => "male"), "count" => 2}).should be_false


        one.to_api_hash.should eq({"locale"=>"ru",
                                   "label"=>"Male got one message",
                                   "context"=>{"user"=>{"gender"=>"male"}, "count"=>{"numeric"=>"one"}},
                                   "rank"=>0})
      end
    end
  end

  describe "context description" do
    describe "with one token" do
      it "should return correct description" do
        context = Tr8n::LanguageContext.create(
            language:     @russian,
            keyword:      "numeric",
            definition:   {
                "token_expression"  => '/.*(count|num|age|hours|minutes|years|seconds)(\d)*$/',
                "variables"         => ['@n']
            },
            description:   "Numeric language context"
        )

        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "one", :definition => "(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))", :description => "{token} mod 10 is 1 and {token} mod 100 is not 11", :examples => "1, 21, 31, 41, 51, 61...")

        one = Tr8n::Translation.create(:label => "You have one message", :context => {"count" => {"numeric" => "one"}}, :language => @russian, :translation_key => @translation_key, :translator => @translator)
        one.context_description.should eq("{count} mod 10 is 1 and {count} mod 100 is not 11")
      end
    end

    describe "with multiple tokens" do
      it "should return correct description" do
        context = Tr8n::LanguageContext.create(
            language:     @russian,
            keyword:      "numeric",
            definition:   {
                "token_expression"  => '/.*(count|num|age|hours|minutes|years|seconds)(\d)*$/',
                "variables"         => ['@n']
            },
            description:   "Numeric language context"
        )
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "one", :definition => "(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))", :description => "{token} mod 10 is 1 and {token} mod 100 is not 11", :examples => "1, 21, 31, 41, 51, 61...")

        context = Tr8n::LanguageContext.create(
            language:     @russian,
            keyword:      "gender",
            definition:   {
                "token_expression"  => '/.*(user|profile)(\d)*$/',
                "variables"         => ['@gender']
            },
            description:   "Gender language context"
        )
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "male", :definition => "(= 'male' @gender)", :description=> "{token} is a male")

        context = Tr8n::LanguageContext.create(
            language:     @russian,
            keyword:      "date",
            definition:   {
                "token_expression"  => '/.*(date)(\d)*$/',
                "variables"         => ['@date']
            },
            description:   "Date language context"
        )
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "future", :definition => "(> (today) @date)", :description=> "{token} is in the future")

        context = Tr8n::LanguageContext.create(
            language:     @russian,
            keyword:      "value",
            definition:   {
                "token_expression"  => '/.*(date)(\d)*$/',
                "variables"         => ['@value']
            },
            description:   "Value language context"
        )
        Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "vowels", :definition => "", :description=> "{token} starts with a vowel")

        one = Tr8n::Translation.create(:label => "Male got one message", :context => {"user" => {"gender" => "male"}, "count" => {"numeric" => "one"}}, :language => @russian, :translation_key => @translation_key, :translator => @translator)
        one.context_description.should eq("{user} is a male; {count} mod 10 is 1 and {count} mod 100 is not 11")

        one = Tr8n::Translation.create(:label => "Male got one message", :context => {"user" => {"gender" => "male"}, "count" => {"numeric" => "one"}, "date" => {"date" => "future"}}, :language => @russian, :translation_key => @translation_key, :translator => @translator)
        one.context_description.should eq("{user} is a male; {count} mod 10 is 1 and {count} mod 100 is not 11; {date} is in the future")

        one = Tr8n::Translation.create(:label => "Male got one message", :context => {"user" => {"gender" => "male", "value" => "vowels"}, "count" => {"numeric" => "one"}, "date" => {"date" => "future"}}, :language => @russian, :translation_key => @translation_key, :translator => @translator)
        one.context_description.should eq("{user} is a male and {user} starts with a vowel; {count} mod 10 is 1 and {count} mod 100 is not 11; {date} is in the future")
      end
    end
  end

  describe "matching translation" do
    it "must verify definition" do
      t = Tr8n::Translation.create(:label => "Male got one message", :context => {"user" => {"gender" => "male"}, "count" => {"numeric" => "one"}}, :language => @russian, :translation_key => @translation_key, :translator => @translator)
      t.matches_context?({"user" => {"gender" => "male"}, "count" => {"numeric" => "one"}})
    end
  end

end
