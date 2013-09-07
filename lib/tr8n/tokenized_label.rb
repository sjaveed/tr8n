#--
# Copyright (c) 2013 Michael Berkovich, tr8nhub.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

module Tr8n
  class TokenizedLabel
   
    # constracts the label  
    def initialize(label)
      @label = label
    end

    def label
      @label
    end

    # scans for all token types    
    def data_tokens(opts = {})
      @data_tokens ||= Tr8n::Tokens::Base.register_tokens(label, :data, opts)
    end

    def data_tokens?
      data_tokens.any?
    end

    def decoration_tokens(opts = {})
      @decoration_tokens ||= Tr8n::Tokens::Base.register_tokens(label, :decoration, opts)
    end

    def decoration_tokens?
      decoration_tokens.any?
    end

    def tokens
      @tokens = data_tokens + decoration_tokens
    end

    def implied_tokens
      # if the implied token is also a translatable token, it is not really implied
      @implied_tokens ||= tokens.select{|token| token.implied? and not translation_token_names.include?(token.name)} 
    end

    def implied_tokens?
      implied_tokens.any?
    end

    def tokens?
      tokens.any?
    end

    # tokens that can be used by the user in translation
    def translation_tokens
      @translation_tokens ||= tokens.select{|token| token.allowed_in_translation?} 
    end

    def translation_token_names
      @translation_token_names ||= translation_tokens.collect{|token| token.name} 
    end

    def translation_tokens?
      translation_tokens.any?
    end

    def suggestion_tokens
      @suggestion_tokens ||= begin
        toks = []
        tokens.each do |token|
          if token.decoration?
            toks << token.name
          else  
            toks << token.sanitized_name          
          end
        end
        toks
      end
    end

    def tokens_by_short_name
      @tokens_by_short_name ||= begin
        hash = {}
        tokens.each do |token|
          hash[token.short_name] = token
        end
        hash
      end
    end

    def allowed_token?(token)
      tokens_by_short_name.keys.include?(token.short_name)
    end
  end
end
