require File.expand_path('../../spec_helper', File.dirname(__FILE__))

describe Tr8n::Tokens::Data do
  describe 'registering tokens' do

    context "incorrect tokens" do
      it "should not be registered" do
        [
          'Hello {user:}',
          'Hello {} and welcome',
          'Hello {user::}'
        ].each do |label|
          Tr8n::Tokens::Data.parse(label).count.should eq(0)
        end
      end
    end

    context "correct tokens" do
      it "should be registered" do
        [
          'Hello {user}',
          'You have {count} messages',
          'You have {count:number}',
          'Hello {user:gender}',
          'Today is {today:date}',
          'Hello {user_list:list}',
          '{long_token_name} like this message',
          'Hello {user1}',
          'Hello {user1:user}',
          'Hello {user1:user::pos} and welcome',
        ].each do |label|
          tokens = Tr8n::Tokens::Data.parse(label)
          tokens.count.should eq(1)
          tokens.first.class.name.should eq("Tr8n::Tokens::Data")
        end

        [
          '{user} has {count} messages',
          '{user1:user} has {count:number} messages'
        ].each do |label|
          tokens = Tr8n::Tokens::Data.parse(label)
          tokens.count.should eq(2)
          tokens.first.class.name.should eq("Tr8n::Tokens::Data")
        end
      end
    end

  end  
end
