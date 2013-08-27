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
end
