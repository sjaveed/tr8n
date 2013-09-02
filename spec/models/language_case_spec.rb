require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe Tr8n::LanguageCase do
  describe "language case creation" do
    before :all do
      @user = User.create(:first_name => "Mike", :gender => "male")
      @translator = Tr8n::Translator.create!(:name => "Mike", :user => @user, :gender => "male")
      @english = Tr8n::Language.create!(:locale => "en-US", :english_name => "English")
      @russian = Tr8n::Language.create!(:locale => "ru", :english_name => "Russian")
    end

    describe "registering cache key" do
      it "should contain language and keyword" do
        lcase = Tr8n::LanguageCase.create(
          language:     @english,
          keyword:      "pos",
          latin_name:   "Possessive",
          native_name:  "Possessive", 
          description:  "Used to indicate possession (i.e., ownership). It is usually created by adding 's to the word", 
          application:  "phrase")
        
        lcase.cache_key.should eq("language_case_[en-US]_[pos]")

        Tr8n::LanguageCase.by_keyword_and_language("pos", @english).should eq(lcase)
      end
    end

    describe "apply" do
      it "should substitute the tokens with appropriate case" do
        lcase = Tr8n::LanguageCase.create(
          language:     @english,
          keyword:      "pos",
          latin_name:   "Possessive",
          native_name:  "Possessive", 
          description:  "Used to indicate possession (i.e., ownership). It is usually created by adding 's to the word", 
          application:  "phrase")
        
        lcase.add_rule(0, {"conditions" => "(match '/s$/' @value)", "operations" => "(append \"'\" @value)"})
        lcase.add_rule(1, {"conditions" => "(not (match '/s$/' @value))", "operations" => "(append \"'s\" @value)"})

        michael = double(:to_s => "Michael", :gender => "male")
        lcase.apply("Michael").should eq("Michael's")
      end
    end
  end


  describe "plurals and singular" do
    before :all do
      @english = Tr8n::Language.create!(:locale => "en-US", :english_name => "English")
    end

    describe "plurals in English" do
      it "should substitute the tokens with appropriate value" do
        lcase = Tr8n::LanguageCase.create(
            language:     @english,
            keyword:      "plural",
            latin_name:   "Plural",
            native_name:  "Plural",
            description:  "Converts singular value to plural value",
            application:  "phrase")

        position = 0
        uncounatable = ['sheep', 'fish', 'series', 'species', 'money', 'rice', 'information', 'equipment']
        lcase.add_rule(position, {"conditions" => "(in '#{uncounatable.join(',')}' @value)", "operations" => "@value"})
        position += 1

        irregular = {
            'move'    =>  'moves',
            'sex'     =>  'sexes',
            'child'   =>  'children',
            'man'     =>  'men',
            'person'  =>  'people'
        }

        irregular.each do |search, replace|
          lcase.add_rule(position, {"conditions" => "(= '#{search}' @value)", "operations" => "(quote '#{replace}')"})
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
          lcase.add_rule(position, {"conditions" => "(match '#{search}' @value)", "operations" => "(replace '#{search}' '#{replace}' @value)"})
          position += 1
        end

        # uncounatable
        lcase.apply("fish").should eq("fish")
        lcase.apply("money").should eq("money")

        # irregular
        lcase.apply("move").should eq("moves")

        # plurals
        lcase.apply("quiz").should eq("quizzes")
        lcase.apply("wife").should eq("wives")

      end
    end

    describe "singular in English" do
      it "should substitute the tokens with appropriate value" do
        lcase = Tr8n::LanguageCase.create(
            language:     @english,
            keyword:      "singular",
            latin_name:   "Singular",
            native_name:  "Singular",
            description:  "Converts plural value to singular value",
            application:  "phrase")

        position = 0
        uncounatable = ['sheep', 'fish', 'series', 'species', 'money', 'rice', 'information', 'equipment']
        lcase.add_rule(position, {"conditions" => "(in '#{uncounatable.join(',')}' @value)", "operations" => "@value"})
        position += 1

        irregular = {
            'moves'     =>  'move',
            'sexes'     =>  'sex',
            'children'  =>  'child',
            'men'       =>  'man',
            'people'    =>  'person'
        }

        irregular.each do |search, replace|
          lcase.add_rule(position, {"conditions" => "(= '#{search}' @value)", "operations" => "(quote '#{replace}')"})
          position += 1
        end

        singular = {
            '/(n)ews$/i'                => "$1ews",
            '/([ti])a$/i'               => "$1um",
            '/((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$/i'  => "$1$2sis",
            '/(^analy)ses$/i'           => "$1sis",
            '/([^f])ves$/i'             => "$1fe",
            '/(hive)s$/i'               => "$1",
            '/(tive)s$/i'               => "$1",
            '/([lr])ves$/i'             => "$1f",
            '/([^aeiouy]|qu)ies$/i'     => "$1y",
            '/(s)eries$/i'              => "$1eries",
            '/(m)ovies$/i'              => "$1ovie",
            '/(x|ch|ss|sh)es$/i'        => "$1",
            '/([m|l])ice$/i'            => "$1ouse",
            '/(bus)es$/i'               => "$1",
            '/(o)es$/i'                 => "$1",
            '/(shoe)s$/i'               => "$1",
            '/(cris|ax|test)es$/i'      => "$1is",
            '/(octop|vir)i$/i'          => "$1us",
            '/(alias|status)es$/i'      => "$1",
            '/^(ox)en$/i'               => "$1",
            '/(vert|ind)ices$/i'        => "$1ex",
            '/(matr)ices$/i'            => "$1ix",
            '/(quiz)zes$/i'             => "$1",
            '/(us)es$/i'                => "$1",
            '/s$/i'                     => ""
        }

        singular.each do |search, replace|
          lcase.add_rule(position, {"conditions" => "(match '#{search}' @value)", "operations" => "(replace '#{search}' '#{replace}' @value)"})
          position += 1
        end

        # uncounatable
        lcase.apply("fish").should eq("fish")
        lcase.apply("money").should eq("money")

        # irregular
        lcase.apply("moves").should eq("move")

        # plurals
        lcase.apply("quizzes").should eq("quiz")
        lcase.apply("wives").should eq("wife")

      end
    end
  end
end
