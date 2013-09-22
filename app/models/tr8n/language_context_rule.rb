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
#-- Tr8n::LanguageContextRule Schema Information
#
# Table name: tr8n_language_context_rules
#
#  id                     INTEGER         not null, primary key
#  language_context_id    integer         
#  translator_id          integer         
#  keyword                varchar(255)    
#  description            varchar(255)    
#  examples               varchar(255)    
#  definition             text            
#  created_at             datetime        not null
#  updated_at             datetime        not null
#
# Indexes
#
#  tr8n_lctxr_lci    (language_context_id, keyword) 
#
#++


class Tr8n::LanguageContextRule < ActiveRecord::Base
  self.table_name = :tr8n_language_context_rules
  attr_accessible :language_context_id, :keyword, :translator_id, :definition, :description, :examples
  attr_accessible :language, :language_context, :translator
  
  belongs_to :language_context,   :class_name => "Tr8n::LanguageContext"   
  belongs_to :language,           :class_name => "Tr8n::Language"
  belongs_to :translator,         :class_name => "Tr8n::Translator"

  serialize :definition

  def fallback?
    keyword == 'other'
  end

  def conditions
    definition["conditions"]
  end

  def conditions_expression
    @conditions_expression ||= definition["conditions_expression"] || Tr8n::RulesEngine::Parser.new(conditions).parse
  end

  def evaluate(vars = {})
    return true if fallback?
    return false if definition.nil?

    re = Tr8n::RulesEngine::Evaluator.new
    vars.each do |key, value|
      re.evaluate(["let", key, value])
    end

    re.evaluate(conditions_expression)
  rescue Exception => ex
    Tr8n::Logger.error("Failed to evaluate settings context rule #{conditions_expression}: #{ex.message}")
    false
  end

  def sanitize_description(token_name)
    return nil unless description
    description.gsub("{token}", "{#{token_name}}")
  end

  def to_api_hash(opts = {})
    {
        "keyword" => keyword,
        "definition" => definition,
        "description" => description,
        "examples" => examples,
    }
  end

end