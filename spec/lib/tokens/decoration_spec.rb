require File.expand_path('../../spec_helper', File.dirname(__FILE__))

describe Tr8n::Tokens::Decoration do
  describe 'identifying tokens' do

    context 'incorrect tokens' do
      it 'should not be registered' do
      	[
					'Hello {bold}',
					'Hello [bold}',
					'Hello [bold]',
					'Hello [[bold]',
					'Hello [[bold]]',
					'Hello [[bold]]',
					'You have [bold {count}] messages',
      	].each do |label|
        	Tr8n::Tokens::Decoration.parse(label).should be_empty
        end
      end
    end

    context 'correct tokens' do
      it 'should be registered' do
      	[
					'Hello [bold: Mike]',
					'Hello [link: test]',
					'Hello [a: test]',
					'Hello [1: test]',
					'You have [bold: {count}] messages',
					'You have [bold: {count|| message}]',
				  '[link: {count} {_messages}]',
					'[link: {count||message}]',
					'[link: {count||person, people}]',
					'[link: {user.name}]'
      	].each do |label|
        	Tr8n::Tokens::Decoration.parse(label).count.should eq(1)
        end

      	[
					'You have [link1: {msg_count|| message}] and [link2: {alert_count|| alert}]',
      	].each do |label|
        	Tr8n::Tokens::Decoration.parse(label).count.should eq(2)
        end
      end
    end

    context 'nested tokens' do
      it 'should be registered' do
        Tr8n::Tokens::Decoration.parse('You have [italic: [bold: {count}] messages]').collect{|t| t.to_s}.should eq(["[bold: {count}]", "[italic: [bold: {count}] messages]"])
        Tr8n::Tokens::Decoration.parse('You have [italic: [bold: {count}] messages]', :exclude_nested => true).collect{|t| t.to_s}.should eq(["[bold: {count}]"])
      end
    end

  end
end