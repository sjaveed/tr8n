require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe Tr8n::LanguageCaseRule do
  describe "language case rules" do

    before :all do
      @user = User.create(:first_name => "Mike", :gender => "male")
      @translator = Tr8n::Translator.create(:name => "Mike", :user => @user, :gender => "male")
      @english = Tr8n::Language.create(:locale => "en-US", :english_name => "English")
      @russian = Tr8n::Language.create(:locale => "ru", :english_name => "Russian")

	    @lcase_en = Tr8n::LanguageCase.create(
	      language:     @english,
	      keyword:      "pos",
	      latin_name:   "Possessive",
	      native_name:  "Possessive", 
	      description:  "Used to indicate possession (i.e., ownership). It is usually created by adding 's to the word", 
	      application:  "phrase")

	    @lcase_ru = Tr8n::LanguageCase.create(
	      language:     @russian,
	      keyword:      "pos",
	      latin_name:   "Possessive",
	      native_name:  "Possessive", 
	      description:  "Used to indicate possession (i.e., ownership).", 
	      application:  "words")
    end

    after :all do
      [@user, @translator, @english, @russian, 
      	@lcase_en, @lcase_ru].each do |obj|
          #obj.destroy if obj
       end       
    end

    describe "evaluating simple rules without genders" do
      it "should result in correct substitution" do
        lcrule = Tr8n::LanguageCaseRule.create(
        		:language => @english,
        		:language_case => @lcase_en,
        		:definition => {
        			"conditions" => "(match '/s$/' @value)",
              "operations" => "(append \"'\" @value)"
            }
        )

        lcrule.should be_a(Tr8n::LanguageCaseRule)

        lcrule.evaluate("Michael").should be_false
        lcrule.evaluate("Anna").should be_false

        lcrule.evaluate("friends").should be_true
        lcrule.apply("friends").should eq("friends'")


        lcrule = Tr8n::LanguageCaseRule.create(
         		:language => @english,
         		:language_case => @lcase_en,
         		:definition => {
                "conditions" => "(not (match '/s$/' @value))",
                "operations" => "(append \"'s\" @value)"
            }
        )

         lcrule.evaluate("Michael").should be_true
         lcrule.apply("Michael").should eq("Michael's")

         lcrule.evaluate("Anna").should be_true
         lcrule.apply("Anna").should eq("Anna's")

         lcrule.evaluate("friends").should be_false

         lcrule = Tr8n::LanguageCaseRule.create(
         		:language => @english,
         		:language_case => @lcase_en,
         		:definition => {
                "conditions" => "(= '1' @value))",
                "operations" => "(quote 'first')"
            }
         )

         lcrule.evaluate("2").should be_false
         lcrule.evaluate("1").should be_true
         lcrule.apply("1").should eq("first")

         lcrule = Tr8n::LanguageCaseRule.create(
         		:language => @english,
         		:language_case => @lcase_en,
         		:definition => {
                "conditions" => "(match '/(0|4|5|6|7|8|9|11|12|13)$/' @value))",
                "operations" => "(append 'th' @value)"
            }
         )

         lcrule.evaluate("4").should be_true
         lcrule.apply("4").should eq("4th")

         lcrule.evaluate("7").should be_true
         lcrule.apply("7").should eq("7th")

      end
    end

     describe "evaluating simple rules with genders" do
       it "should result in correct substitution" do
         anna = double(:gender => "female", :name => "Anna")
         michael = double(:gender => "male", :name => "Michael")

         @context = Tr8n::LanguageContext.create(
             language:     @russian,
             keyword:      "gender",
             definition:   {
                 "token_expression"  => '/.*(profile|user)(\d)*$/',
                 "variables"         => ['@gender']
             },
             description:   "Gender language context"
         )

         Tr8n::Config.stub(:context_rules) {
           {
               "gender" => {
                   "variables" => {
                       "@gender" => "gender",
                   }
               }
           }
         }

         lcrule1 = Tr8n::LanguageCaseRule.create(
         		:language => @russian,
         		:language_case => @lcase_ru,
         		:definition => {
                "conditions" => "(&& (= 'female' @gender) (= '1' @value))",
                "operations" => "(quote 'pervaya')"
            }
         )

         lcrule1.gender_variables(anna).should eq({"@gender"=>"female"})
         lcrule1.gender_variables(michael).should eq({"@gender"=>"male"})

         lcrule1.evaluate("1", michael).should be_false
         lcrule1.evaluate("1", anna).should be_true
         lcrule1.apply("1").should eq("pervaya")

         lcrule2 = Tr8n::LanguageCaseRule.create(
         		:language => @russian,
         		:language_case => @lcase_ru,
         		:definition => {
                "conditions" => "(&& (= 'male' @gender) (= '1' @value))",
                "operations" => "(quote 'pervii')"
            }
         )

         lcrule2.evaluate("1", anna).should be_false
         lcrule2.evaluate("1", michael).should be_true
         lcrule2.apply("1").should eq("pervii")
			end
		end

     describe "applying rules" do
     	describe "when using replace" do
        it "it should correctly replace values" do
           lcrule = Tr8n::LanguageCaseRule.create(
	         		:language => @english,
	         		:language_case => @lcase_ru,
	         		:definition => {
                  "conditions" => "(= '1' @value)",
                  "operations" => "(quote '1st')"
	            }
           )

	          lcrule.evaluate("1").should be_true
         	  lcrule.apply("1").should eq("1st")
      	end
      end

     	describe "when using append" do
      	 	it "it should correctly append values" do
	         lcrule = Tr8n::LanguageCaseRule.create(
	         		:language => @english,
	         		:language_case => @lcase_ru,
	         		:definition => {
                  "conditions" => "(= '1' @value)",
                  "operations" => "(append 'st' @value)"
	            }
           )

	         lcrule.evaluate("1").should be_true
	         lcrule.apply("1").should eq("1st")
      	 	end
       end

     	describe "when using prepend" do
      	 	it "it should correctly prepend values" do
	         lcrule = Tr8n::LanguageCaseRule.create(
	         		:language => @english,
	         		:language_case => @lcase_ru,
	         		:definition => {
                  "conditions" => "(match '/^(q|w|r|t|p|s|d|f|g|j|k|h|l|z|x|c|v|b|n|m)/' @value)",
                  "operations" => "(prepend 'a ' @value)"
              }
	         )

	         lcrule.evaluate("car").should be_true
	         lcrule.apply("car").should eq("a car")

	         lcrule = Tr8n::LanguageCaseRule.create(
	         		:language => @english,
	         		:language_case => @lcase_ru,
	         		:definition => {
                  "conditions" => "(match '/^(e|u|i|o|a)/' @value)",
                  "operations" => "(prepend 'an ' @value)"
              }
	         )

	         lcrule.evaluate("apple").should be_true
	         lcrule.apply("apple").should eq("an apple")
      	 	end
       end
     end
  end

  describe "pluralization rules in English" do
    describe "when using pluralize" do
      it "it should correctly replace the value" do
        english = Tr8n::Language.create(:locale => "en-US", :english_name => "English")

        lcase = Tr8n::LanguageCase.create(
            language:     english,
            keyword:      "plural",
            latin_name:   "Pluralization rule",
            native_name:  "Pluralization",
            description:  "Used to pluralize words",
            application:  "phrase")

        lcrule = Tr8n::LanguageCaseRule.create(
            :language => english,
            :language_case => lcase,
            :definition => {
                "conditions" => "(in 'sheep, fish, series, species, money, rice, information, equipment' @value)",
                "operations" => "@value"
            }
        )

        lcrule.evaluate("sheep").should be_true
        lcrule.apply("sheep").should eq("sheep")

        lcrule = Tr8n::LanguageCaseRule.create(
            :language => english,
            :language_case => lcase,
            :definition => {
                "conditions" => "(= 'move' @value)",
                "operations" => "(quote 'moves')"
            }
        )

        lcrule.evaluate("move").should be_true
        lcrule.apply("move").should eq("moves")

        lcrule = Tr8n::LanguageCaseRule.create(
            :language => english,
            :language_case => lcase,
            :definition => {
                "conditions" => "(match '/(quiz)$/' @value)",
                "operations" => "(replace '/(quiz)$/i' '$1zes' @value)"
            }
        )

        expect("quiz".gsub(eval('/(quiz)$/i'), '$1zes'.gsub(/\$(\d+)/, '\\\\\1'))).to eq("quizzes")
        lcrule.evaluate("quiz").should be_true
        lcrule.apply("quiz").should eq("quizzes")

        lcrule = Tr8n::LanguageCaseRule.create(
            :language => english,
            :language_case => lcase,
            :definition => {
                "conditions" => "(match '/(?:([^f])fe|([lr])f)$/' @value)",
                "operations" => "(replace '/(?:([^f])fe|([lr])f)$/i' '$1$2ves' @value)"
            }
        )
        lcrule.evaluate("wife").should be_true
        lcrule.apply("wife").should eq("wives")

        lcrule.evaluate("knife").should be_true
        lcrule.apply("knife").should eq("knives")
      end

      it "should return a correct API hash" do
        english = Tr8n::Language.create(:locale => "en-US", :english_name => "English")

        lcase = Tr8n::LanguageCase.create(
            language:     english,
            keyword:      "plural",
            latin_name:   "Pluralization rule",
            native_name:  "Pluralization",
            description:  "Used to pluralize words",
            application:  "phrase")

        lcrule = Tr8n::LanguageCaseRule.create(
            :position => 0,
            :language => english,
            :language_case => lcase,
            :definition => {
                "conditions" => "(match '/(?:([^f])fe|([lr])f)$/' @value)",
                "operations" => "(replace '/(?:([^f])fe|([lr])f)$/i' '$1$2ves' @value)"
            },
            :description => "If {token} ends in 'f' 'lf', etc... use 'ves'",
            :examples => "wife => wives, elf => elves, etc..."
        )

        lcrule.to_api_hash.should eq({"position"=>0,
                                      "definition"=>
                                          {"conditions"=>"(match '/(?:([^f])fe|([lr])f)$/' @value)",
                                           "operations"=>"(replace '/(?:([^f])fe|([lr])f)$/i' '$1$2ves' @value)"},
                                      "description"=>"If {token} ends in 'f' 'lf', etc... use 'ves'",
                                      "examples"=>"wife => wives, elf => elves, etc..."})
      end
    end
  end
end
