require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe Tr8n::LanguageContext do

  before :all do
    @user = User.create(:first_name => "Mike", :gender => "male")
    @translator = Tr8n::Translator.create(:name => "Mike", :user => @user, :gender => "male")

    @english = Tr8n::Language.create(:locale => "en-US", :english_name => "English")
    @russian = Tr8n::Language.create(:locale => "ru", :english_name => "Russian")
  end

  describe "finding context" do
    it "should return correct context" do
      Tr8n::LanguageContext.cache_key("ru", "numeric").should eq("language_context_[ru]_[numeric]")

      context = Tr8n::LanguageContext.create(
          language:     @english,
          keyword:      "numeric",
          definition:   {
              "token_expression"  => '/.*(count|num|age|hours|minutes|years|seconds)(\d)*$/',
              "variables"         => ['@n']
          },
          description:   "Numeric language context"
      )

      context.cache_key.should eq("language_context_[en-US]_[numeric]")
      context.cache_key_for_rules.should eq("language_context_rules_[#{context.id}]")


      Tr8n::LanguageContext.by_keyword_and_language("numeric", @english).should eq(context)

    end
  end

  describe "context api hash" do
    it "should return correct hash" do

      context = Tr8n::LanguageContext.create(
          language:     @english,
          keyword:      "numeric",
          definition:   {
              "token_expression"  => '/.*(count|num|age|hours|minutes|years|seconds)(\d)*$/',
              "variables"         => ['@n']
          },
          description:   "Numeric language context"
      )

      Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "one", :definition => {"conditions" => "(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))"}, :description => "{n} mod 10 is 1 and {n} mod 100 is not 11", :examples => "1, 21, 31, 41, 51, 61...")
      Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "few", :definition => {"conditions" => "(&& (in '2..4' (mod @n 10)) (not (in '12..14' (mod @n 100))))"}, :description => "{n} mod 10 in 2..4 and {n} mod 100 not in 12..14", :examples => "2-4, 22-24, 32-34...")
      Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "many", :definition => {"conditions" => "(|| (= 0 (mod @n 10)) (in '5..9' (mod @n 10)) (in '11..14' (mod @n 100)))"}, :description => "{n} mod 10 is 0 or {n} mod 10 in 5..9 or {n} mod 100 in 11..14", :examples => "0, 5-20, 25-30, 35-40...")
      Tr8n::LanguageContextRule.create(:language_context => context, :keyword => "other", :description => "all other values")

      context.to_api_hash.should  eq({
        "keyword"=>"numeric",
        "description"=>"Numeric language context",
        "definition"=>
            {"token_expression"=> "/.*(count|num|age|hours|minutes|years|seconds)(\\d)*$/",
             "variables"=>["@n"]},
        "rules"=>
            {"one"=>
                 {"keyword"=>"one",
                  "definition"=>{"conditions" => "(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))"},
                  "description"=>"{n} mod 10 is 1 and {n} mod 100 is not 11",
                  "examples"=>"1, 21, 31, 41, 51, 61..."},
             "few"=>
                 {"keyword"=>"few",
                  "definition"=>{"conditions" => "(&& (in '2..4' (mod @n 10)) (not (in '12..14' (mod @n 100))))"},
                  "description"=>"{n} mod 10 in 2..4 and {n} mod 100 not in 12..14",
                  "examples"=>"2-4, 22-24, 32-34..."},
             "many"=>
                 {"keyword"=>"many",
                  "definition"=>{"conditions" => "(|| (= 0 (mod @n 10)) (in '5..9' (mod @n 10)) (in '11..14' (mod @n 100)))"},
                  "description"=>"{n} mod 10 is 0 or {n} mod 10 in 5..9 or {n} mod 100 in 11..14",
                  "examples"=>"0, 5-20, 25-30, 35-40..."},
             "other"=>
                 {"keyword"=>"other",
                  "definition"=>nil,
                  "description"=>"all other values",
                  "examples"=>nil}}
      })

    end
  end

  describe "matching tokens" do
    it "should identify the right tokens" do
      @context = Tr8n::LanguageContext.create(
          language:     @english,
          keyword:      "numeric",
          definition:   {
              "token_expression"  => '/.*(count|num|age|hours|minutes|years|seconds)(\d)*$/',
              "variables"         => ['@n']
          },
          description:   "Numeric language context"
      )

      @context.token_expression.should eq(/.*(count|num|age|hours|minutes|years|seconds)(\d)*$/)
      @context.applies_to_token?("num").should be_true
      @context.applies_to_token?("num1").should be_true
      @context.applies_to_token?("profile_num1").should be_true
      @context.applies_to_token?("profile_num21").should be_true
      @context.applies_to_token?("profile").should be_false

      @context.applies_to_token?("num_years").should be_true
      @context.applies_to_token?("count1").should be_true
      @context.applies_to_token?("count2").should be_true
    end
  end

  describe "gender rules" do
    describe "loading variables" do
      it "should return assigned variables" do
        @context = Tr8n::LanguageContext.create(
            language:     @english,
            keyword:      "gender",
            definition:   {
                "token_expression"  => '/.*(profile|user|actor|target)(\d)*$/',
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
        obj = double(:gender => "male")
        @context.vars(obj).should eq({"@gender" => "male"})

        Tr8n::Config.stub(:context_rules) {
          {
              "gender" => {
                  "variables" => {
                      "@gender" => lambda{|obj| obj.gender},
                  }
              }
          }
        }
        obj = double(:gender => "male")
        @context.vars(obj).should eq({"@gender" => "male"})
      end
    end

    describe "evaluate rules" do
      it "should return matching rule" do
        @context = Tr8n::LanguageContext.create(
            language:     @english,
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

        male = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "male", :definition => {"conditions" => "(= 'male' @gender)"})
        female = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "female", :definition => {"conditions" => "(= 'female' @gender)"})
        other = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "other")

        @context.fallback_rule.should eq(other)

        @context.find_matching_rule(double(:gender => "male")).should eq(male)
        @context.find_matching_rule(double(:gender => "female")).should eq(female)
        @context.find_matching_rule(double(:gender => "unknown")).should eq(other)

        # unknown goes before other
        unknown = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "unknown", :definition => {"conditions" => "(&& (!= 'male' @gender) (!= 'female' @gender))"})
        @context.reset!
        @context.rules.count.should eq(4)
        @context.find_matching_rule(double(:gender => "unknown")).should eq(unknown)
      end
    end
  end

  describe "genders rules" do
    describe "loading variables" do
      it "should return assigned variables" do
        @context = Tr8n::LanguageContext.create(
            language:     @english,
            keyword:      "genders",
            definition:   {
                "token_expression"  => '/.*(profiles|users|actors|targets)(\d)*$/',
                "variables"         => ['@genders', '@count']
            },
            description:   "Language context for list of users"
        )

        Tr8n::Config.stub(:context_rules) {
          {
              "genders" => {
                  "variables" => {
                      "@genders" => lambda{|list|
                        list.collect{|u| u.gender}
                      },
                      "@count" => lambda{|list| list.count},
                  }
              }
          }
        }

        obj = [double(:gender => "male"), double(:gender => "female")]
        @context.vars(obj).should eq({"@genders" => ["male", "female"], "@count" => 2})
      end
    end

    describe "evaluate rules" do
      it "should return matching rule" do
        @context = Tr8n::LanguageContext.create(
            language:     @english,
            keyword:      "genders",
            definition:   {
                "token_expression"  => '/.*(profiles|users)(\d)*$/',
                "variables"         => ['@genders']
            },
            description:   "Gender language context"
        )

        Tr8n::Config.stub(:context_rules) {
          {
              "genders" => {
                  "variables" => {
                      "@genders" => lambda{|list| list.collect{|u| u.gender}},
                  }
              }
          }
        }

        one_male = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "one_male", :definition => {"conditions" => "(&& (= 1 (count @genders)) (all @genders 'male'))"})
        one_female = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "one_female", :definition => {"conditions" => "(&& (= 1 (count @genders)) (all @genders 'female'))"})
        one_unknown = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "one_unknown", :definition => {"conditions" => "(&& (= 1 (count @genders)) (all @genders 'unknown'))"})
        other = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "other")

        @context.find_matching_rule([double(:gender => "male")]).should eq(one_male)
        @context.find_matching_rule([double(:gender => "female")]).should eq(one_female)
        @context.find_matching_rule([double(:gender => "unknown")]).should eq(one_unknown)
        @context.find_matching_rule([double(:gender => "male"), double(:gender => "male")]).should eq(other)

        # unknown goes before other
        at_least_two = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "at_least_two", :definition => {"conditions" => "(> (count @genders) 1)"})
        @context.reset!
        @context.rules.count.should eq(5)
        @context.find_matching_rule([double(:gender => "male"), double(:gender => "male")]).should eq(at_least_two)

        at_least_two.destroy

        all_male = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "all_male", :definition => {"conditions" => "(&& (> (count @genders) 1) (all @genders 'male'))"})
        all_female = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "all_female", :definition => {"conditions" => "(&& (> (count @genders) 1) (all @genders 'female'))"})
        @context.reset!
        @context.rules.count.should eq(6)

        all_male.evaluate({"@genders" => ["male", "male"]}).should be_true

        @context.find_matching_rule([double(:gender => "male"), double(:gender => "male")]).should eq(all_male)
        @context.find_matching_rule([double(:gender => "female"), double(:gender => "female")]).should eq(all_female)
        @context.find_matching_rule([double(:gender => "male"), double(:gender => "female")]).should eq(other)
      end
    end
  end

  describe "list rules" do
    describe "loading variables" do
      it "should return assigned variables" do
        @context = Tr8n::LanguageContext.create(
            language:     @english,
            keyword:      "list",
            definition:   {
                "token_expression"  => '/.*(list)(\d)*$/',
                "variables"         => ['@count']
            },
            description:   "Language context for lists"
        )

        Tr8n::Config.stub(:context_rules) {
          {
              "list" => {
                  "variables" => {
                      "@count" => "count",
                  }
              }
          }
        }

        obj = ["apple", "banana"]
        @context.vars(obj).should eq({"@count" => 2})
      end
    end

    describe "evaluate rules" do
      it "should return matching rule" do
        @context = Tr8n::LanguageContext.create(
            language:     @english,
            keyword:      "list",
            definition:   {
                "token_expression"  => '/.*(list)(\d)*$/',
                "variables"         => ['@count']
            },
            description:   "List language context"
        )

        Tr8n::Config.stub(:context_rules) {
          {
              "list" => {
                  "variables" => {
                      "@count" => "count",
                  }
              }
          }
        }

        one = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "one", :definition => {"conditions" => "(= 1 @count)"})
        two = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "three", :definition => {"conditions" => "(= 2 @count)"})
        other = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "other")

        @context.find_matching_rule(["apple"]).should eq(one)
        @context.find_matching_rule(["apple", "banana"]).should eq(two)
        @context.find_matching_rule(["apple", "banana", "grapes"]).should eq(other)
      end
    end
  end

  describe "numeric rules" do
    describe "loading variables" do
      it "should return assigned variables" do
        @context = Tr8n::LanguageContext.create(
            language:     @english,
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
                  "token_expression" => '/.*(count|num|age|hours|minutes|years|seconds)(\d)*$/',
                  "variables" => {
                      "@n" => "to_i",
                  }
              }
          }
        }
        obj = double(:to_i => 10)
        @context.vars(obj).should eq({"@n" => 10})

        Tr8n::Config.stub(:context_rules) {
          {
              "numeric" => {
                  "variables" => {
                      "@n" => lambda{|obj| obj.value.to_i},
                  }
              }
          }
        }
        obj = double(:value => "15")
        @context.vars(obj).should eq({"@n" => 15})

        Tr8n::Config.stub(:context_rules) {
          {
              "numeric" => {
                  "variables" => {
                      "@n" => "invalid_method",
                  }
              }
          }
        }
        expect {
          obj = double(:value => 15)
          @context.vars(obj)
        }.to raise_error
      end
    end

    describe "evaluate rules" do
      it "should return matching rule" do
        @context = Tr8n::LanguageContext.create(
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

        one = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "one", :definition => {"conditions" => "(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))"}, :description => "{n} mod 10 is 1 and {n} mod 100 is not 11", :examples => "1, 21, 31, 41, 51, 61...")
        few = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "few", :definition => {"conditions" => "(&& (in '2..4' (mod @n 10)) (not (in '12..14' (mod @n 100))))"}, :description => "{n} mod 10 in 2..4 and {n} mod 100 not in 12..14", :examples => "2-4, 22-24, 32-34...")
        many = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "many", :definition => {"conditions" => "(|| (= 0 (mod @n 10)) (in '5..9' (mod @n 10)) (in '11..14' (mod @n 100)))"}, :description => "{n} mod 10 is 0 or {n} mod 10 in 5..9 or {n} mod 100 in 11..14", :examples => "0, 5-20, 25-30, 35-40...")

        @context.rules.count.should eq(3)
        @context.find_matching_rule(1).should eq(one)
        @context.find_matching_rule(2).should eq(few)
        @context.find_matching_rule(0).should eq(many)
      end
    end
  end

  describe "date rules" do
    describe "loading variables" do
      it "should return assigned variables" do
        @context = Tr8n::LanguageContext.create(
            language:     @english,
            keyword:      "list",
            definition:   {
                "token_expression"  => '/.*(date)(\d)*$/',
                "variables"         => ['@date']
            },
            description:   "Language context for dates"
        )

        Tr8n::Config.stub(:context_rules) {
          {
              "list" => {
                  "variables" => {
                  }
              }
          }
        }

        today = Date.today
        @context.vars(Date.today).should eq({"@date" => today})
      end
    end

    describe "evaluate rules" do
      it "should return matching rule" do
        @context = Tr8n::LanguageContext.create(
            language:     @english,
            keyword:      "list",
            definition:   {
                "token_expression"  => '/.*(date)(\d)*$/',
                "variables"         => ['@date']
            },
            description:   "Language context for dates"
        )

        Tr8n::Config.stub(:context_rules) {
          {
              "list" => {
                  "variables" => {
                  }
              }
          }
        }

        present = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "present", :definition => {"conditions" => "(= (today) @date)"})
        past = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "past", :definition => {"conditions" => "(> (today) @date)"})
        future = Tr8n::LanguageContextRule.create(:language_context => @context, :keyword => "past", :definition => {"conditions" => "(< (today) @date)"})

        @context.find_matching_rule(Date.today).should eq(present)
        @context.find_matching_rule(Date.today - 1.day).should eq(past)
        @context.find_matching_rule(Date.today + 1.day).should eq(future)
      end
    end
  end

end
