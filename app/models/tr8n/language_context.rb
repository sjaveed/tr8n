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
#
#-- Tr8n::LanguageContext Schema Information
#
# Table name: tr8n_language_contexts
#
#  id               INTEGER         not null, primary key
#  language_id      integer         
#  translator_id    integer         
#  keyword          varchar(255)    
#  description      varchar(255)    
#  definition       text            
#  created_at       datetime        not null
#  updated_at       datetime        not null
#
# Indexes
#
#  tr8n_lctx_lk    (language_id, keyword) 
#
#++

class Tr8n::LanguageContext < ActiveRecord::Base
  self.table_name = :tr8n_language_contexts
  
  attr_accessible :language_id, :translator_id, :keyword, :description, :definition
  attr_accessible :language, :translator

  after_save :clear_cache
  after_destroy :clear_cache

  belongs_to :language, :class_name => "Tr8n::Language"
  belongs_to :translator, :class_name => "Tr8n::Translator"

  has_many   :language_context_rules, :class_name => "Tr8n::LanguageContextRule", :dependent => :destroy

  serialize :definition

  def self.cache_key(locale, keyword)
    "language_context_[#{locale}]_[#{keyword}]"
  end

  def cache_key
    self.class.cache_key(language.locale, keyword)
  end

  def self.by_keyword_and_language(keyword, language = Tr8n::Config.current_language)
    Tr8n::Cache.fetch(cache_key(language.locale, keyword)) do
      where(:language_id => language.id, :keyword => keyword).first
    end
  end

  def self.cache_key_for_contexts(locale)
    "language_contexts_[#{locale}]"
  end

  def cache_key_for_contexts
    self.class.cache_key_for_rules(language.locale)
  end

  def self.by_token_and_language(token_name, language = Tr8n::Config.current_language)
    contexts = Tr8n::Cache.fetch(cache_key_for_contexts(language.locale)) do
      where(:language_id => language.id).all
    end

    contexts.each do |ctx|
      return ctx if ctx.applies_to_token?(token_name)
    end

    nil
  end

  def self.cache_key_for_rules(id)
    "language_context_rules_[#{id}]"
  end

  def cache_key_for_rules
    self.class.cache_key_for_rules(id)
  end

  def rules
    @rules ||= begin
      Tr8n::Cache.fetch(cache_key_for_rules) do
        language_context_rules
      end
    end
  end

  def config
    Tr8n::Config.context_rules[keyword] || {}
  end

  # Context rule can be mapped to a transform token using the sequence of rule keys with settings cases
  # This is done so that developers don't have to name each value in the piped token
  # For example, in the numeric context rule, a transform token in its full form can look like this:
  #
  #  {count:numeric|| one: message, other: messages}
  #
  # To simplify the syntax, each settings can provide it's construct for mapping, like so:
  #
  # [{"one": "{$0}", "other": "{$0}::plural"}]
  #
  # Developers then can use the simplified form:
  #
  #  {count|| message}
  #
  # This means that the first parameter corresponds to rule "one", the second parameter corresponds to rule "many",
  # but uses the value of "one" and applies plural case to it
  #
  def token_mapping
    definition["token_mapping"]
  end

  def default_rule
    definition["default_rule"]
  end

  def token_expression
    @token_expression ||= begin
      exp = config["token_expression"] || definition["token_expression"]
      exp = Regexp.new(exp[1..-2]) if exp.is_a?(String)
      exp
    end
  end

  def variables
    definition["variables"]
  end

  def applies_to_token?(token)
    token_expression.match(token) != nil
  end

  def vars(token)
    vars = {}
    variables.each do |key|
      unless config["variables"]
        vars[key] = token
        next
      end

      method = config["variables"][key]
      if method.is_a?(String)
        vars[key] = token.send(method)
      elsif method.is_a?(Proc)
        vars[key] = method.call(token)
      else
        vars[key] = token
      end
    end
    vars
  end

  def fallback_rule
    rules.detect{|rule| rule.fallback?}
  end

  def rule_by_keyword(keyword)
    rules.detect{|rule| rule.keyword == keyword}
  end

  def find_matching_rule(token)
    token_vars = vars(token)
    rules.each do |rule|
      next if rule.fallback?
      return rule if rule.evaluate(token_vars)
    end
    fallback_rule
  end

  def save_with_log!(translator)
    if self.id
      if changed?
        self.translator = translator
        translator.updated_language_context!(self)
      end
    else  
      self.translator = translator
      translator.added_language_context!(self)
    end

    save  
  end
  
  def destroy_with_log!(translator)
    translator.deleted_language_context!(self)
    
    destroy
  end

  def clear_cache
    Tr8n::Cache.delete(cache_key)
    Tr8n::Cache.delete(cache_key_for_rules)
    Tr8n::Cache.delete(cache_key_for_contexts)
  end

  def to_api_hash(opts = {})
    hash = {
      "keyword" => keyword,
      "description" => description,
      "definition" => definition,
      "rules" => {}
    }
    rules.each do |rule|
       hash["rules"][rule.keyword] = rule.to_api_hash
    end
    hash
  end

end
