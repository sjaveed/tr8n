require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe Tr8n::LanguageContextRule do

    describe "finding fallback rules" do
      it "should return fallback rule" do

        rule = Tr8n::LanguageContextRule.create(:keyword => "one", :definition => {"conditions" => "(= 1 @n)"}, :examples => "1")
        rule.fallback?.should be_false

        rule = Tr8n::LanguageContextRule.create(:keyword => "other", :examples => "0, 2-999; 1.2, 2.07...")
        rule.fallback?.should be_true
      end
    end

    describe "evaluating rules" do
      it "should return correct results" do
        rule = Tr8n::LanguageContextRule.create(:keyword => "one", :definition => {"conditions" => "(= 1 @n)"}, :examples => "1")
        rule.evaluate().should be_false
        rule.evaluate({"@n" => 1}).should be_true
        rule.evaluate({"@n" => 2}).should be_false
        rule.evaluate({"@n" => 0}).should be_false

        one = Tr8n::LanguageContextRule.create(:keyword => "one", :definition => {"conditions" => "(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))"}, :description => "{n} mod 10 is 1 and {n} mod 100 is not 11", :examples => "1, 21, 31, 41, 51, 61...")
        few = Tr8n::LanguageContextRule.create(:keyword => "few", :definition => {"conditions" => "(&& (in '2..4' (mod @n 10)) (not (in '12..14' (mod @n 100))))"}, :description => "{n} mod 10 in 2..4 and {n} mod 100 not in 12..14", :examples => "2-4, 22-24, 32-34...")
        many = Tr8n::LanguageContextRule.create(:keyword => "many", :definition => {"conditions" => "(|| (= 0 (mod @n 10)) (in '5..9' (mod @n 10)) (in '11..14' (mod @n 100)))"}, :description => "{n} mod 10 is 0 or {n} mod 10 in 5..9 or {n} mod 100 in 11..14", :examples => "0, 5-20, 25-30, 35-40...")

        {
            [1, 21, 31, 101, 121] => one,
            [2, 3, 4, 22, 23, 24, 102, 103, 104] => few,
            [0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 17, 20, 25, 26, 28, 30, 35, 36, 38, 39, 40] => many
        }.each do |vals, rule|
          vals.each do |val|
            vars = {"@n" => val}
            rule.evaluate(vars).should be_true
          end
        end

        {
            [2, 3, 4, 9] => one,
            [5, 6, 7, 8, 9] => few,
            [1, 2, 3, 4] => many
        }.each do |vals, rule|
          vals.each do |val|
            vars = {"@n" => val}
            rule.evaluate(vars).should be_false
          end
        end

        one_male = Tr8n::LanguageContextRule.create(:keyword => "one_male", :definition => {"conditions" => "(&& (= 1 (count @genders)) (all @genders 'male'))"}, :description => "List contains one male user")
        one_female = Tr8n::LanguageContextRule.create(:keyword => "one_female", :definition => {"conditions" => "(&& (= 1 (count @genders)) (all @genders 'female'))"}, :description => "List contains one female user")
        one_unknown = Tr8n::LanguageContextRule.create(:keyword => "one_unknown", :definition => {"conditions" => "(&& (= 1 (count @genders)) (all @genders 'unknown'))"}, :description => "List contains one user with unknown gender")
        many = Tr8n::LanguageContextRule.create(:keyword => "many", :definition => {"conditions" => "(> (count @genders) 1)"}, :description => "List contains two or more users")

        one_male.evaluate({"@genders" => ["male"]}).should be_true
        one_male.evaluate({"@genders" => ["male", "male"]}).should be_false

        one_female.evaluate({"@genders" => ["female"]}).should be_true
        many.evaluate({"@genders" => ["female", "male"]}).should be_true

        one_unknown.evaluate({"@genders" => ["unknown"]}).should be_true

        many_male = Tr8n::LanguageContextRule.create(:keyword => "one", :definition => {"conditions" => "(&& (> (count @genders) 1) (all @genders 'male'))"}, :description => "List contains at least two users, all male")
        many_male.evaluate({"@genders" => ["male", "male"]}).should be_true
      end
    end

    describe "api hash" do
      it "should return the correct structure" do
        one = Tr8n::LanguageContextRule.create(:keyword => "one", :definition => {"conditions" => "(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))"}, :description => "{n} mod 10 is 1 and {n} mod 100 is not 11", :examples => "1, 21, 31, 41, 51, 61...")
        one.to_api_hash.should eq("keyword"=>"one",
                                  "definition"=>{"conditions" => "(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))"},
                                  "description"=>"{n} mod 10 is 1 and {n} mod 100 is not 11",
                                  "examples"=>"1, 21, 31, 41, 51, 61...")
      end
    end
end
