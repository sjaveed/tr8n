require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe Tr8n::TokenizedLabel do
  describe 'registering tokens' do

    context "registering correct tokens" do
      it "should register all tokens" do
        str = 'Dear {user:gender}, you have [bold: {count:number|| new message}] in your mailbox!'

        english = Tr8n::Language.create!(:locale => "en-US", :english_name => "English")
        Tr8n::Config.set_language(english)

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

        plural_case = Tr8n::LanguageCase.create(
            language:     english,
            keyword:      "plural",
            latin_name:   "Plural",
            native_name:  "Plural",
            description:  "Converts singular value to plural value",
            application:  "phrase")

        plural_case.add_rule(0, {"conditions" => "(= 'new message' @value)", "operations" => "(quote 'new messages')"})

        label = Tr8n::TokenizedLabel.new(str)
        label.label.should eq(str)

        label.tokens?.should be_true
        label.data_tokens?.should be_true
        label.decoration_tokens?.should be_true

        label.data_tokens.count.should eq(2)
        label.decoration_tokens.count.should eq(1)

        label.tokens.count.should eq(3)

        label.sanitized_tokens_hash.keys.should eq(["{user}", "{count}", "[bold: ]"])

        label.translation_tokens?.should be_true
        label.translation_tokens.count.should eq(3)

        san_str = "Dear {user}, you have [bold: {count} new messages] in your mailbox!"
        label.sanitized_label.should eq(san_str)

        label.suggestion_tokens.should eq(["{user}", "{count}", "bold"])

        label.words.should eq(["Dear", "User", "Have", "Bold", "Count", "Messages", "Your", "Mailbox"])

        label.tokens.each do |token|
          label.allowed_token?(token).should be_true
        end

      end
    end

  end  
end
