require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe Tr8n::TranslationKey do
  describe 'translation keys' do

    before :all do 
      @user = User.create(:first_name => "Mike", :name => "Mike", :gender => "male")
      @translator = Tr8n::Translator.create!(:name => "Mike", :user => @user, :gender => "male")

      @user2 = User.create(:first_name => "Anna", :name => "Anna", :gender => "female")
      @translator2 = Tr8n::Translator.create!(:name => "Anna", :user => @user2, :gender => "female")

      @english = setup_english_language
      @russian = setup_russian_language
    end

    context "creating new translation key" do
      it "should create a unique hash" do
        key = Tr8n::TranslationKey.find_or_create("Hello World", "We must start with this sentence!")
        assert key.key   

        the_key = Tr8n::TranslationKey.find_or_create("Hello World", "We must start with this sentence!")
        key.key.should eq(the_key.key)

        key2 = Tr8n::TranslationKey.find_or_create("Hello World", "We must not start with this sentence!")
        key.key.should_not eq(key2.key)
      end
    end
    
    context "creating new translation key with tokens" do
      it "should parse the tokens correctly" do
        key = Tr8n::TranslationKey.find_or_create("Hello {user}, you have {count} messages in your inbox")

        key.key.should_not be(nil)
        key.translation_tokens.should_not be_empty
        key.decoration_tokens.should be_empty
        key.tokens.count.should == 2
        key.tokens.collect{|t| t.sanitized_name}.should include("{user}", "{count}")
        key.translation_tokens.collect{|t| t.sanitized_name}.should include("{user}", "{count}")
      end
    end

    context "translating simple strings with default language" do
      it "should return original value" do
        key = Tr8n::TranslationKey.find_or_create("Hello World")
        key.translate(@english).should eq("Hello World")

        key = Tr8n::TranslationKey.find_or_create("Hello {world}")
        key.translate(@english, :world => "World").should  eq("Hello World")

        key = Tr8n::TranslationKey.find_or_create("{hello_world}")
        key.translate(@english, :hello_world => "Hello World").should eq("Hello World")

        @user.to_s.should eq("Mike")

        Tr8n::Config.stub(:context_rules) {
          {
              "gender" => {
                  "variables" => {
                      "@gender" => "gender",
                  }
              },
              "number" => {
                  "variables" => {
                      "@n" => "to_i",
                  }
              }
          }
        }

        key = Tr8n::TranslationKey.find_or_create("Dear {user:gender}")
        key.translate(@english, :user => @user).should eq("Dear Mike")
        key.translate(@english, :user => [@user, @user.name]).should eq("Dear Mike")
        key.translate(@english, :user => [@user, :name]).should eq("Dear Mike")
        key.translate(@english, :user => [@user, lambda{|user| user.name}]).should eq("Dear Mike")
        key.translate(@english, :user => [@user, lambda{|user, tom| "#{user.name} and #{tom}"}, "Tom"]).should  eq("Dear Mike and Tom")

        key = Tr8n::TranslationKey.find_or_create("{user:gender} updated {user:gender|his,her} profile")
        key.translate(@english, {:user => @user}).should eq("Mike updated his profile")
        key.translate(@english, {:user => @user2}).should eq("Anna updated her profile")
      end
    end

    describe "translating labels into a foreign language" do
      context "labels with no rules" do
        it "should return correct translations" do
          key = Tr8n::TranslationKey.find_or_create("Hello World")
          key.add_translation("Privet Mir", nil, @russian, @translator)
          key.translate(@russian).should eq("Privet Mir")

          key = Tr8n::TranslationKey.find_or_create("Hello {user}")
          key.add_translation("Privet {user}", nil, @russian, @translator)
          key.translate(@russian, {:user => @user}).should eq("Privet Mike")

          key = Tr8n::TranslationKey.find_or_create("You have {count} messages.")
          key.add_translation("U vas est {count} soobshenii.", nil, @russian, @translator)
          key.translate(@russian, {:count => 5}).should eq("U vas est 5 soobshenii.")
        end
      end

      context "labels with numeric rules" do
        it "should return correct translations" do
          key = Tr8n::TranslationKey.find_or_create("You have {count||message}.")
          key.add_translation("U vas est {count} soobshenie.",  {"count" => {"number" => "one"}},  @russian, @translator)
          key.add_translation("U vas est {count} soobsheniya.", {"count" => {"number" => "few"}},  @russian, @translator)
          key.add_translation("U vas est {count} soobshenii.",  {"count" => {"number" => "many"}}, @russian, @translator)

          key.translate(@russian, {:count => 1}).should eq("U vas est 1 soobshenie.")
          key.translate(@russian, {:count => 101}).should eq("U vas est 101 soobshenie.")
          key.translate(@russian, {:count => 11}).should eq("U vas est 11 soobshenii.")
          key.translate(@russian, {:count => 111}).should eq("U vas est 111 soobshenii.")

          key.translate(@russian, {:count => 5}).should eq("U vas est 5 soobshenii.")
          key.translate(@russian, {:count => 26}).should eq("U vas est 26 soobshenii.")
          key.translate(@russian, {:count => 106}).should eq("U vas est 106 soobshenii.")

          key.translate(@russian, {:count => 3}).should eq("U vas est 3 soobsheniya.")
          key.translate(@russian, {:count => 13}).should eq("U vas est 13 soobshenii.")
          key.translate(@russian, {:count => 23}).should eq("U vas est 23 soobsheniya.")
          key.translate(@russian, {:count => 103}).should eq("U vas est 103 soobsheniya.")
        end
      end


      context "labels with gender rules" do
        it "should return correct translations" do
          key = Tr8n::TranslationKey.find_or_create("{user| other: Born on}:")
          key.add_translation("Rodilsya:", {"user" => {"gender" => "male"}}, @russian, @translator)
          key.add_translation("Rodilas':", {"user" => {"gender" => "female"}}, @russian, @translator)
          key.add_translation("Rodilsya/Rodilas':", {"user" => {"gender" => "other"}}, @russian, @translator)

          Tr8n::Config.stub(:context_rules) {
            {
                "gender" => {
                    "variables" => {
                        "@gender" => "gender",
                    }
                },
            }
          }
          male = double(:gender => "male", :to_s => "Michael")
          female = double(:gender => "female", :to_s => "Anna")
          unknown = double(:gender => "unknown", :to_s => "Alex")

          @english.default?.should be_true

          key.translate(@english, {:user => male}).should eq("Born on:")
          key.translate(@english, {:user => female}).should eq("Born on:")

          @russian.default?.should be_false

          key.translate(@russian, {:user => male}).should eq("Rodilsya:")
          key.translate(@russian, {:user => female}).should eq("Rodilas':")
          key.translate(@russian, {:user => unknown}).should eq("Rodilsya/Rodilas':")

          key = Tr8n::TranslationKey.find_or_create("{user} updated {user|his, her} profile.")
          key.add_translation("{user} obnovil svoi profil'.", {"user" => {"gender" => "male"}}, @russian, @translator)
          key.add_translation("{user} obnovila svoi profil'.", {"user" => {"gender" => "female"}}, @russian, @translator)
          key.add_translation("{user} obnovil/obnovila svoi profil'.", {"user" => {"gender" => "other"}}, @russian, @translator)

          key.translate(@english, {:user => male}).should eq("Michael updated his profile.")
          key.translate(@english, {:user => female}).should eq("Anna updated her profile.")

          key.translate(@russian, {:user => male}).should eq("Michael obnovil svoi profil'.")
          key.translate(@russian, {:user => female}).should eq("Anna obnovila svoi profil'.")
          key.translate(@russian, {:user => unknown}).should eq("Alex obnovil/obnovila svoi profil'.")
        end
      end

    end


  #

  #
  #

  #    context "labels with mixed rules and tokens" do
  #      it "should return correct translations" do
  #        definition = {operator: "is", value: "male"}
  #        grule1 = Tr8n::GenderRule.create(:language => @russian, :definition => definition)
  #        definition = {operator: "is", value: "female"}
  #        grule2 = Tr8n::GenderRule.create(:language => @russian, :definition => definition)
  #        definition = {operator: "is", value: "unknown"}
  #        grule3 = Tr8n::GenderRule.create(:language => @russian, :definition => definition)
  #
  #        definition = {multipart: true, part1: "ends_in", value1: "1", operator: "and", part2: "does_not_end_in", value2: "11"}
  #        nrule1 = Tr8n::NumericRule.create(:language => @russian, :definition => definition)
  #        definition = {multipart: true, part1: "ends_in", value1: "2,3,4", operator: "and", part2: "does_not_end_in", value2: "12,13,14"}
  #        nrule2 = Tr8n::NumericRule.create(:language => @russian, :definition => definition)
  #        definition = {multipart: false, part1: "ends_in", value1: "0,5,6,7,8,9,11,12,13,14"}
  #        nrule3 = Tr8n::NumericRule.create(:language => @russian, :definition => definition)
  #
  #        male = mock("male")
  #        male.stub!(:to_s).and_return("Michael")
  #        male.stub!(:gender).and_return("male")
  #        female = mock("female")
  #        female.stub!(:to_s).and_return("Anna")
  #        female.stub!(:gender).and_return("female")
  #        unknown = mock("unknown")
  #        unknown.stub!(:to_s).and_return("Alex")
  #        unknown.stub!(:gender).and_return("unknown")
  #
  #        key = Tr8n::TranslationKey.find_or_create("Dear {user}, you have [bold: {count||message}].")
  #        key.add_translation("Dorogoi {user}, u vas est' [bold: {count} soobshenie].", [
  #              {:token=>"user", :rule_id=>[grule1.id]}, {:token=>"count", :rule_id=>[nrule1.id]}
  #        ], @russian, @translator)
  #        key.add_translation("Dorogoi {user}, u vas est' [bold: {count} soobsheniya].", [
  #              {:token=>"user", :rule_id=>[grule1.id]}, {:token=>"count", :rule_id=>[nrule2.id]}
  #        ], @russian, @translator)
  #        key.add_translation("Dorogoi {user}, u vas est' [bold: {count} soobshenii].", [
  #              {:token=>"user", :rule_id=>[grule1.id]}, {:token=>"count", :rule_id=>[nrule3.id]}
  #        ], @russian, @translator)
  #        key.add_translation("Dorogaya {user}, u vas est' [bold: {count} soobshenie].", [
  #              {:token=>"user", :rule_id=>[grule2.id]}, {:token=>"count", :rule_id=>[nrule1.id]}
  #        ], @russian, @translator)
  #        key.add_translation("Dorogaya {user}, u vas est' [bold: {count} soobsheniya].", [
  #              {:token=>"user", :rule_id=>[grule2.id]}, {:token=>"count", :rule_id=>[nrule2.id]}
  #        ], @russian, @translator)
  #        key.add_translation("Dorogaya {user}, u vas est' [bold: {count} soobshenii].", [
  #              {:token=>"user", :rule_id=>[grule2.id]}, {:token=>"count", :rule_id=>[nrule3.id]}
  #        ], @russian, @translator)
  #
  #        key.translate(@english, {:user => male, :count => 1, :bold => "<b>{$0}</b>"}).should eq("Dear Michael, you have <b>1 message</b>.")
  #        key.translate(@english, {:user => female, :count => 1, :bold => "<b>{$0}</b>"}).should eq("Dear Anna, you have <b>1 message</b>.")
  #
  #        key.translate(@english, {:user => male, :count => 5, :bold => "<b>{$0}</b>"}).should eq("Dear Michael, you have <b>5 messages</b>.")
  #        key.translate(@english, {:user => female, :count => 5, :bold => "<b>{$0}</b>"}).should eq("Dear Anna, you have <b>5 messages</b>.")
  #
  #        key.translate(@russian, {:user => male, :count => 1, :bold => "<b>{$0}</b>"}).should eq("Dorogoi Michael, u vas est' <b>1 soobshenie</b>.")
  #        key.translate(@russian, {:user => female, :count => 1, :bold => "<b>{$0}</b>"}).should eq("Dorogaya Anna, u vas est' <b>1 soobshenie</b>.")
  #
  #        key.translate(@russian, {:user => male, :count => 2, :bold => "<b>{$0}</b>"}).should eq("Dorogoi Michael, u vas est' <b>2 soobsheniya</b>.")
  #        key.translate(@russian, {:user => female, :count => 2, :bold => "<b>{$0}</b>"}).should eq("Dorogaya Anna, u vas est' <b>2 soobsheniya</b>.")
  #
  #        key.translate(@russian, {:user => male, :count => 5, :bold => "<b>{$0}</b>"}).should eq("Dorogoi Michael, u vas est' <b>5 soobshenii</b>.")
  #        key.translate(@russian, {:user => female, :count => 5, :bold => "<b>{$0}</b>"}).should eq("Dorogaya Anna, u vas est' <b>5 soobshenii</b>.")
  #      end
  #    end
  #
  #    context "labels with languages cases" do
  #      describe "when using a possesive case in English" do
  #        it "should add s or ' at the end of the phrase" do
  #          michael = mock("male")
  #          michael.stub!(:to_s).and_return("Michael")
  #          michael.stub!(:gender).and_return("male")
  #          anna = mock("female")
  #          anna.stub!(:to_s).and_return("Anna")
  #          anna.stub!(:gender).and_return("female")
  #
  #          language_case = Tr8n::LanguageCase.create(:language => @english,
  #                        :translator => @translator, :keyword => "pos",
  #                        :latin_name => "Possessive", :application => "phrase")
  #
  #          language_case.add_rule({
  #                                  part1: "ends_in", value1: "s",
  #                                  operation: "append",
  #                                  operation_value: "'"
  #                                 }, :translator => @translator)
  #          language_case.add_rule({
  #                                  part1: "does_not_end_in",
  #                                  value1: "s",
  #                                  operation: "append",
  #                                  operation_value: "'s"
  #                                  }, :translator => @translator)
  #
  #          key = Tr8n::TranslationKey.find_or_create("{actor} updated {target::pos} profile.")
  #          key.translate(@english, {:actor => michael, :target => anna}).should eq("Michael updated Anna's profile.")
  #        end
  #      end
  #
  #      describe "when using a full ordinal case in English" do
  #        it "should use first, second, or add th to the end of numbers" do
  #          lcase = Tr8n::LanguageCase.create(
  #              :language => @english,
  #              :translator => @translator,
  #              :keyword => "ord",
  #              :description => "The adjective form of the cardinal numbers",
  #              :latin_name => "Ordinal",
  #              :application => "phrase"
  #          )
  #          lcase.add_rule({
  #              part1:                "is",
  #              value1:               "1",
  #              operation:            "replace",
  #              operation_value:      "first"
  #          }, :translator => @translator)
  #          lcase.add_rule({
  #              part1:                "is",
  #              value1:               "2",
  #              operation:            "replace",
  #              operation_value:      "second"
  #          }, :translator => @translator)
  #          lcase.add_rule({
  #              part1:                "is",
  #              value1:               "3",
  #              operation:            "replace",
  #              operation_value:      "third"
  #          }, :translator => @translator)
  #          lcase.add_rule({
  #              multipart:            "true",
  #              part1:                "ends_in",
  #              value1:               "1",
  #              operator:             "and",
  #              part2:                "does_not_end_in",
  #              value2:               "11",
  #              operation:            "append",
  #              operation_value:      "st"
  #          }, :translator => @translator)
  #          lcase.add_rule({
  #              multipart:            "true",
  #              part1:                "ends_in",
  #              value1:               "2",
  #              operator:             "and",
  #              part2:                "does_not_end_in",
  #              value2:               "12",
  #              operation:            "append",
  #              operation_value:      "nd"
  #          }, :translator => @translator)
  #          lcase.add_rule({
  #              multipart:            "true",
  #              part1:                "ends_in",
  #              value1:               "3",
  #              operator:             "and",
  #              part2:                "does_not_end_in",
  #              value2:               "13",
  #              operation:            "append",
  #              operation_value:      "rd"
  #          }, :translator => @translator)
  #          lcase.add_rule({
  #              part1:                "ends_in",
  #              value1:               "0,4,5,6,7,8,9,11,12,13",
  #              operation:            "append",
  #              operation_value:      "th"
  #          }, :translator => @translator)
  #
  #          @english = Tr8n::Language.find(@english.id)
  #
  #          key = Tr8n::TranslationKey.find_or_create("This is your {count::ord} notice!")
  #          key.translate(@english, {:count => 1}).should eq("This is your first notice!")
  #          key.translate(@english, {:count => 2}).should eq("This is your second notice!")
  #          key.translate(@english, {:count => 3}).should eq("This is your third notice!")
  #          key.translate(@english, {:count => 4}).should eq("This is your 4th notice!")
  #          key.translate(@english, {:count => 5}).should eq("This is your 5th notice!")
  #          key.translate(@english, {:count => 12}).should eq("This is your 12th notice!")
  #          key.translate(@english, {:count => 42}).should eq("This is your 42nd notice!")
  #          key.translate(@english, {:count => 13}).should eq("This is your 13th notice!")
  #          key.translate(@english, {:count => 23}).should eq("This is your 23rd notice!")
  #        end
  #       end
  #
  #    end
  #
  #  end

  end  
end
