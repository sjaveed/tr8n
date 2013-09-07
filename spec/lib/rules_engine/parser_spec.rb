require File.expand_path('../../spec_helper', File.dirname(__FILE__))

describe Tr8n::RulesEngine::Parser do
  describe "#parser" do
    it "parses expressions" do

      expect(Tr8n::RulesEngine::Parser.new("hello world").tokens).to be_nil
      expect(Tr8n::RulesEngine::Parser.new("hello world").parse).to eq("hello world")

      expect(Tr8n::RulesEngine::Parser.new("@var").parse).to eq("@var")

      expect(Tr8n::RulesEngine::Parser.new("(= 1 (mod n 10))").tokens).to eq(
          ["(", "=", "1", "(", "mod", "n", "10", ")", ")"]
      )

      expect(Tr8n::RulesEngine::Parser.new("(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))").tokens).to eq(
          ["(", "&&", "(", "=", "1", "(", "mod", "@n", "10", ")", ")", "(", "!=", "11", "(", "mod", "@n", "100", ")", ")", ")"]
      )

      {
          "@value" => '@value',
          "(= '1' @value)" => ["=", '1', '@value'],
          "(= 1 @value)" => ["=", 1, '@value'],
          "(= 1 1)" => ["=", 1, 1],
          "(+ 1 1)" => ["+", 1, 1],
          "(= 1 (mod n 10))" => ["=", 1, ["mod", "n", 10]],
          "(&& 1 1)" => ["&&", 1, 1],
          "(mod @n 10)" => ["mod", "@n", 10],
          "(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))" => ["&&", ["=", 1, ["mod", "@n", 10]], ["!=", 11, ["mod", "@n", 100]]],
          "(&& (in '2..4' (mod @n 10)) (not (in '12..14' (mod @n 100))))" => ["&&", ["in", "2..4", ["mod", "@n", 10]], ["not", ["in", "12..14", ["mod", "@n", 100]]]],
          "(|| (= 0 (mod @n 10)) (in '5..9' (mod @n 10)) (in '11..14' (mod @n 100)))" => ["||", ["=", 0, ["mod", "@n", 10]], ["in", "5..9", ["mod", "@n", 10]], ["in", "11..14", ["mod", "@n", 100]]]
      }.each do |source, target|
        expect(Tr8n::RulesEngine::Parser.new(source).parse).to eq(target)
      end

    end
  end

  describe "#decorator" do
    it "decorates expressions" do

      {
          "@value" => "<span class='tr8n_sexp'><span class='variable'>@value</span></span>",
          "(= '1' @value)" => "<span class='tr8n_sexp'><span class='open_paren'>(</span><span class='symbol'>=</span><span class='string'>'1'</span><span class='variable'>@value</span><span class='close_paren'>)</span></span>",
          "(= 1 @value)" => "<span class='tr8n_sexp'><span class='open_paren'>(</span><span class='symbol'>=</span><span class='number'>1</span><span class='variable'>@value</span><span class='close_paren'>)</span></span>",
          "(+ 1 1)" => "<span class='tr8n_sexp'><span class='open_paren'>(</span><span class='symbol'>+</span><span class='number'>1</span><span class='number'>1</span><span class='close_paren'>)</span></span>",
          "(mod @n 10)" => "<span class='tr8n_sexp'><span class='open_paren'>(</span><span class='symbol'>mod</span><span class='variable'>@n</span><span class='number'>10</span><span class='close_paren'>)</span></span>",
      }.each do |source, target|
        expect(Tr8n::RulesEngine::Parser.new(source).decorate).to eq(target)
      end

    end
  end
end
