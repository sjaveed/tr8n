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
#-- Tr8n::LanguageCaseRule Schema Information
#
# Table name: tr8n_language_case_rules
#
#  id                  INTEGER         not null, primary key
#  language_case_id    integer         not null
#  language_id         integer         
#  translator_id       integer         
#  definition          text            not null
#  position            integer         
#  created_at          datetime        not null
#  updated_at          datetime        not null
#  description         varchar(255)    
#  examples            varchar(255)    
#
# Indexes
#
#  tr8n_lcr_t     (translator_id) 
#  tr8n_lcr_l     (language_id) 
#  tr8n_lcr_lc    (language_case_id) 
#
#++

class Tr8n::LanguageCaseRule < ActiveRecord::Base
  self.table_name = :tr8n_language_case_rules
  attr_accessible :language_case_id, :language_id, :translator_id, :definition, :position, :description, :examples
  attr_accessible :language, :language_case, :translator
  
  belongs_to :language_case,  :class_name => "Tr8n::LanguageCase"   
  belongs_to :language,       :class_name => "Tr8n::Language"
  belongs_to :translator,     :class_name => "Tr8n::Translator"
  
  serialize :definition

  def self.cache_key(id)
    "language_case_rule_[#{id}]"
  end

  def cache_key
    self.class.cache_key(id)
  end

  def conditions
    definition["conditions"]
  end

  def conditions_expression
    @conditions_expression ||= definition["conditions_expression"] || Tr8n::RulesEngine::Parser.new(conditions).parse
  end

  def operations
    definition["operations"]
  end

  def operations_expression
    @operations_expression ||= definition["operations_expression"] || Tr8n::RulesEngine::Parser.new(operations).parse
  end

  def gender_variables(object)
    return {} unless conditions.index('@gender')
    return {"@gender" => "unknown"} unless object
    context = Tr8n::LanguageContext.by_keyword_and_language("gender", language)
    return {"@gender" => "unknown"} unless context
    context.vars(object)
  end

  def evaluate(value, object = nil)
    return false if conditions.nil?

    re = Tr8n::RulesEngine::Evaluator.new
    re.evaluate(["let", "@value", value])

    gender_variables(object).each do |key, value|
      re.evaluate(["let", key, value])
    end

    re.evaluate(conditions_expression)
  rescue Exception => ex
    Tr8n::Logger.error("Failed to evaluate language case #{conditions}: #{ex.message}")
    value
  end

  def apply(value)
    value = value.to_s
    return value if operations.nil?

    re = Tr8n::RulesEngine::Evaluator.new
    re.evaluate(["let", "@value", value])

    re.evaluate(operations_expression)
  rescue Exception => ex
    Tr8n::Logger.error("Failed to apply language case rule [case: #{language_case.id}] [rule: #{id}] [conds: #{conditions_expression}] [opers: #{operations_expression}]: #{ex.message}")
    value
  end

  def describe
    return description unless description.blank?
    conditions
  end

  def to_api_hash(opts = {})
    {
        "description"             => description,
        "examples"                => examples,
        "conditions"              => conditions,
        "conditions_expression"   => conditions_expression,
        "operations"              => operations,
        "operations_expression"   => operations_expression,
    }
  end

end