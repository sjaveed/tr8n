require File.expand_path('../../spec_helper', File.dirname(__FILE__))

describe Tr8n::Tokens::Decoration do
  describe 'identifying fragments' do

    context 'parsing fragments' do
      it 'should return the right fragments' do

        d = Tr8n::Tokens::Decoration.new("Hello World")
        d.fragments.should eq(["[tr8n]", "Hello World", "[/tr8n]"])
        d.parse.should eq(["tr8n", "Hello World"])

        d = Tr8n::Tokens::Decoration.new("[bold: Hello World]")
        d.fragments.should eq(["[tr8n]", "[bold:", " Hello World", "]", "[/tr8n]"])
        d.parse.should eq(["tr8n", ["bold", "Hello World"]])

        # broken
        d = Tr8n::Tokens::Decoration.new("[bold: Hello World")
        d.fragments.should eq(["[tr8n]", "[bold:", " Hello World", "[/tr8n]"])
        d.parse.should eq(["tr8n", ["bold", "Hello World"]])

        d = Tr8n::Tokens::Decoration.new("[bold: Hello [strong: World]]")
        d.fragments.should eq(["[tr8n]", "[bold:", " Hello ", "[strong:", " World", "]", "]", "[/tr8n]"])
        d.parse.should eq(["tr8n", ["bold", "Hello ", ["strong", "World"]]])

        # broken
        d = Tr8n::Tokens::Decoration.new("[bold: Hello [strong: World]")
        d.fragments.should eq(["[tr8n]", "[bold:", " Hello ", "[strong:", " World", "]", "[/tr8n]"])
        d.parse.should eq(["tr8n", ["bold", "Hello ", ["strong", "World"]]])

        d = Tr8n::Tokens::Decoration.new("[bold1: Hello [strong22: World]]")
        d.fragments.should eq(["[tr8n]", "[bold1:", " Hello ", "[strong22:", " World", "]", "]", "[/tr8n]"])
        d.parse.should eq(["tr8n", ["bold1", "Hello ", ["strong22", "World"]]])

        d = Tr8n::Tokens::Decoration.new("[bold: Hello, [strong: how] [weak: are] you?]")
        d.fragments.should eq(["[tr8n]", "[bold:", " Hello, ", "[strong:", " how", "]", " ", "[weak:", " are", "]", " you?", "]", "[/tr8n]"])
        d.parse.should eq(
                           ["tr8n", ["bold", "Hello, ", ["strong", "how"], " ", ["weak", "are"], " you?"]]
                       )

        # broken
        d = Tr8n::Tokens::Decoration.new("[bold: Hello, [strong: how [weak: are] you?]")
        d.fragments.should eq(["[tr8n]", "[bold:", " Hello, ", "[strong:", " how ", "[weak:", " are", "]", " you?", "]", "[/tr8n]"])
        d.parse.should eq(
                           ["tr8n", ["bold", "Hello, ", ["strong", "how ", ["weak", "are"], " you?"]]]
                       )

        d = Tr8n::Tokens::Decoration.new("[link: you have [italic: [bold: {count}] messages] [light: in your mailbox]]")
        d.fragments.should eq(
                               ["[tr8n]", "[link:", " you have ", "[italic:", " ", "[bold:", " {count}", "]", " messages", "]", " ", "[light:", " in your mailbox", "]", "]", "[/tr8n]"]
                           )
        d.parse.should eq(
                           ["tr8n", ["link", "you have ", ["italic", "", ["bold", "{count}"], " messages"], " ", ["light", "in your mailbox"]]]
                       )

        d = Tr8n::Tokens::Decoration.new("[link: you have [italic: [bold: {count}] messages] [light: in your mailbox]]")
        d.fragments.should eq(
                               ["[tr8n]", "[link:", " you have ", "[italic:", " ", "[bold:", " {count}", "]", " messages", "]", " ", "[light:", " in your mailbox", "]", "]", "[/tr8n]"]
                           )
        d.parse.should eq(
                           ["tr8n", ["link", "you have ", ["italic", "", ["bold", "{count}"], " messages"], " ", ["light", "in your mailbox"]]]
                       )

        d = Tr8n::Tokens::Decoration.new("[link] you have [italic: [bold: {count}] messages] [light: in your mailbox] [/link]")
        d.fragments.should eq(
                               ["[tr8n]", "[link]", " you have ", "[italic:", " ", "[bold:", " {count}", "]", " messages", "]", " ", "[light:", " in your mailbox", "]", " ", "[/link]", "[/tr8n]"]
                           )
        d.parse.should eq(
                           ["tr8n", ["link", " you have ", ["italic", "", ["bold", "{count}"], " messages"], " ", ["light", "in your mailbox"], " "]]
                       )
      end

      it 'should ignore invalid tokens' do
        [
            'Hello {bold}',
            'Hello [bold}',
            'You have [bold {count}] messages',
        ].each do |label|
          d = Tr8n::Tokens::Decoration.new(label)
          d.parse
          d.tokens.count.should eq(0)
        end
      end

      it 'should register fragments' do
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
            '[link: {user.name}]',
            'Hello [bold]',
            'Hello [[bold]',
            'Hello [[bold]]',
            'Hello [[bold]]',
        ].each do |label|
          d = Tr8n::Tokens::Decoration.new(label)
          d.parse
          d.tokens.count.should eq(1)
        end

        [
            'You have [link1: {msg_count|| message}] and [link2: {alert_count|| alert}]',
        ].each do |label|
          d = Tr8n::Tokens::Decoration.new(label)
          d.parse
          d.tokens.count.should eq(2)
        end

      end
    end

    context 'evaluating fragments' do
      it 'should substitute fragments correctly' do

        d = Tr8n::Tokens::Decoration.new("[bold: Hello World]")
        d.substitute.should eq("<strong>Hello World</strong>")

        d = Tr8n::Tokens::Decoration.new("[bold: Hello World")
        d.substitute.should eq("<strong>Hello World</strong>")

        d = Tr8n::Tokens::Decoration.new("[bold]Hello World[/bold]")
        d.substitute.should eq("<strong>Hello World</strong>")

        d = Tr8n::Tokens::Decoration.new("[bold] Hello World [/bold]")
        d.substitute.should eq("<strong> Hello World </strong>")

        d = Tr8n::Tokens::Decoration.new("[p: Hello World]", :p => lambda{|v| "<p>#{v}</p>"})
        d.substitute.should eq("<p>Hello World</p>")

        d = Tr8n::Tokens::Decoration.new("[p]Hello World[/p]", :p => lambda{|v| "<p>#{v}</p>"})
        d.substitute.should eq("<p>Hello World</p>")

        d = Tr8n::Tokens::Decoration.new("[link: you have 5 messages]", :link => lambda{|v| "<a href='http://mail.google.com'>#{v}</a>"})
        d.substitute.should eq("<a href='http://mail.google.com'>you have 5 messages</a>")

        d = Tr8n::Tokens::Decoration.new("[link: you have {count||message}]", :link => lambda{|v| "<a href='http://mail.google.com'>#{v}</a>"})
        d.substitute.should eq("<a href='http://mail.google.com'>you have {count||message}</a>")

        d = Tr8n::Tokens::Decoration.new("[link]you have 5 messages[/link]", :link => lambda{|v| "<a href='http://mail.google.com'>#{v}</a>"})
        d.substitute.should eq("<a href='http://mail.google.com'>you have 5 messages</a>")

        d = Tr8n::Tokens::Decoration.new("[link]you have {count||message}[/link]", :link => lambda{|v| "<a href='http://mail.google.com'>#{v}</a>"})
        d.substitute.should eq("<a href='http://mail.google.com'>you have {count||message}</a>")

        d = Tr8n::Tokens::Decoration.new("[link]you have [bold: {count||message}][/link]", :link => lambda{|v| "<a href='http://mail.google.com'>#{v}</a>"})
        d.substitute.should eq("<a href='http://mail.google.com'>you have <strong>{count||message}</strong></a>")

      end
    end

  end
end