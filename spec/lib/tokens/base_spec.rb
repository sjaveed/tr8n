# encoding: UTF-8

require File.expand_path('../../spec_helper', File.dirname(__FILE__))

describe Tr8n::Tokens::Base do
  before :all do
    @english = setup_english_language
    Tr8n::Config.set_language(@english)
  end

  describe "initialize" do
    it "should parse data token" do
      tkey = Tr8n::TranslationKey.new({:label => "Hello {user}", :locale => 'en-US'})
      token = tkey.tokens.first

      expect(token.class.name).to eq("Tr8n::Tokens::Data")
      expect(token.label).to eq(tkey.label)
      expect(token.full_name).to eq("{user}")
      expect(token.short_name).to eq("user")
      expect(token.key).to eq(:user)
      expect(token.case_keys).to eq([])
      expect(token.context_keys).to eq([])
      expect(token.decoration?).to be_false

      expect(token.name(:parens => true, :context_keys => true)).to eq('{user}')

      tkey = Tr8n::TranslationKey.new({:label => "Hello {user:gender::pos}", :locale => 'en-US'})
      token = tkey.tokens.first

      expect(token.class.name).to eq("Tr8n::Tokens::Data")
      expect(token.label).to eq(tkey.label)
      expect(token.full_name).to eq("{user:gender::pos}")
      expect(token.short_name).to eq("user")
      expect(token.key).to eq(:user)
      expect(token.case_keys).to eq(['pos'])
      expect(token.context_keys).to eq(['gender'])
      expect(token.decoration?).to be_false

      expect(token.name(:parens => true, :context_keys => true)).to eq('{user:gender}')
      expect(token.name(:parens => true, :case_keys => true)).to eq('{user::pos}')
    end
  end

  describe "substitute" do
    it "should substitute values" do
      tkey = Tr8n::TranslationKey.new({:label => "Hello {user}", :locale => 'en-US'})
      token = tkey.tokens.first

      user = User.create({:first_name => "Tom", :last_name => "Anderson", :gender => "Male", :name => "Tom Anderson"})
      user.stub(:last_name_with_prefix) {|prefix| "#{prefix} #{user.last_name}"}

      # tr("Hello {user}", "", {:user => current_user}}
      expect(token.token_value(user, {}, @english)).to eq(user.to_s)

      # tr("Hello {user}", "", {:user => [current_user]}}
      expect(token.token_value([user], {}, @english)).to eq(user.to_s)

      # tr("Hello {user}", "", {:user => [current_user, current_user.name]}}
      expect(token.token_value([user, user.first_name], {}, @english)).to eq(user.first_name)

      # tr("Hello {user}", "", {:user => [current_user, "{$0} {$1}", "param1"]}}
      expect(token.token_value([user, "{$0} {$1}", "param1"], {}, @english)).to eq(user.to_s + " param1")
      expect(token.token_value([user, "{$0} {$1} {$2}", "param1", "param2"], {}, @english)).to eq(user.to_s + " param1 param2")

      # tr("Hello {user}", "", {:user => [current_user, :name]}}
      expect(token.token_value([user, :first_name], {}, @english)).to eq(user.first_name)

      # tr("Hello {user}", "", {:user => [current_user, :method_name, "param1"]}}
      user.stub(:last_name_with_prefix) {|prefix| "#{prefix} #{user.last_name}"}
      expect(token.token_value([user, :last_name_with_prefix, 'Mr.'], {}, @english)).to eq("Mr. Anderson")

      # tr("Hello {user}", "", {:user => [current_user, lambda{|user| user.name}]}}
      expect(token.token_value([user, lambda{|user| user.to_s}], {}, @english)).to eq(user.to_s)

      # tr("Hello {user}", "", {:user => [current_user, lambda{|user, param1| user.name}, "param1"]}}
      expect(token.token_value([user, lambda{|user, param1| user.to_s + " " + param1}, "extra_param1"], {}, @english)).to eq(user.to_s + " extra_param1")

      # tr("Hello {user}", "", {:user => {:object => current_user, :value => current_user.name}]}}
      expect(token.token_value({:object => user, :value => user.to_s}, {}, @english)).to eq(user.to_s)

      # tr("Hello {user}", "", {:user => {:object => current_user, :attribute => :first_name}]}}
      expect(token.token_value({:object => user, :attribute => :first_name}, {}, @english)).to eq(user.first_name)
      expect(token.token_value({:object => {:first_name => "Michael"}, :attribute => :first_name}, {}, @english)).to eq("Michael")
    end

    it "should perform complete substitution" do
      tkey = Tr8n::TranslationKey.new({:label => "Hello {user}", :locale => 'en-US'})
      token = tkey.tokens.first

      user = User.create({:name => "Tom Anderson", :first_name => "Tom", :last_name => "Anderson", :gender => "Male"})
      user.stub(:last_name_with_prefix) {|prefix| "#{prefix} #{user.last_name}"}

      [
        {:user => user},                                                                        "Hello Tom Anderson",
        {:user => [user]},                                                                      "Hello Tom Anderson",
        {:user => [user, user.first_name]},                                                     "Hello Tom",
        {:user => [user, "{$0} {$1}", "param1"]},                                               "Hello Tom Anderson param1",
        {:user => [user, "{$0} {$1} {$2}", "param1", "param2"]},                                "Hello Tom Anderson param1 param2",
        {:user => [user, :first_name]},                                                         "Hello Tom",
        {:user => [user, :last_name_with_prefix, 'Mr.']},                                       "Hello Mr. Anderson",
        {:user => [user, lambda{|user| user.to_s}]},                                            "Hello Tom Anderson",
        {:user => [user, lambda{|user, param1| user.to_s + " " + param1}, "extra_param1"]},     "Hello Tom Anderson extra_param1",
        {:user => {:object => user, :value => user.to_s}},                                      "Hello Tom Anderson",
        {:user => {:object => user, :attribute => :first_name}},                                "Hello Tom",
        {:user => {:object => {:first_name => "Michael"}, :attribute => :first_name}},          "Hello Michael"
      ].each_slice(2).to_a.each do |pair|
        expect(token.substitute(@tkey, @english, tkey.label, pair.first, {})).to eq(pair.last)
      end

    end

    it "should substitute token with array values" do
      tkey = Tr8n::TranslationKey.new({
        :label => "Hello {users}",
        :locale => 'en-US'
      })
      tlabel = tkey.tokenized_label
      token = tlabel.tokens.first

      users = []
      1.upto(6) do |i|
        users << double(:first_name => "First name #{i}", :last_name => "Last name #{i}", :gender => "Male")
      end

      expect(token.token_value([users, :first_name], {}, @english)).to match("2 others")

      expect(token.token_value([users, [:first_name], {
        :translate_items => false,
        :expandable => false,
        :minimizable => true,
        :to_sentence => true,
        :limit => 4,
        :separator => ", ",
        :description => nil,
        :andor => 'and'
      }], {}, @english)).to eq("First name 1, First name 2, First name 3, First name 4 and 2 others")

      expect(token.token_value([users, [:first_name], {
        :translate_items => false,
        :expandable => false,
        :minimizable => true,
        :to_sentence => false,
        :limit => 4,
        :separator => ", ",
        :description => nil,
        :andor => 'and'
      }], {}, @english)).to eq("First name 1, First name 2, First name 3, First name 4, First name 5, First name 6")

      expect(token.token_value([users, [:first_name], {
        :translate_items => false,
        :expandable => false,
        :minimizable => true,
        :to_sentence => true,
        :limit => 4,
        :separator => ", ",
        :description => nil,
        :andor => 'or'
      }], {}, @english)).to eq("First name 1, First name 2, First name 3, First name 4 or 2 others")

      expect(token.token_value([users, [:first_name], {
        :translate_items => false,
        :expandable => false,
        :minimizable => true,
        :to_sentence => true,
        :limit => 2,
        :separator => ", ",
        :description => nil,
        :andor => 'or'
      }], {}, @english)).to eq("First name 1, First name 2 or 4 others")

      expect(token.token_value([users, [:first_name], {
        :translate_items => false,
        :expandable => false,
        :minimizable => true,
        :to_sentence => true,
        :limit => 2,
        :separator => " & ",
        :description => nil,
        :andor => 'or'
      }], {}, @english)).to eq("First name 1 & First name 2 or 4 others")

    end
  end

end
