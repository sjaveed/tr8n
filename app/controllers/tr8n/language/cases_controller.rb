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

class Tr8n::Language::CasesController < Tr8n::Language::BaseController

  def index

  end

  def view
    @lcase = Tr8n::LanguageCase.find_by_id(params[:id])
    unless @lcase
      trfe("Invalid case id")
      return redirect_to(:action => :index)
    end
  end

  def case_modal
    @lcase = Tr8n::LanguageCase.find_by_id(params[:id]) if params[:id]
    @lcase ||= Tr8n::LanguageCase.new
    if request.post? and params[:lcase]
      @lcase.language = tr8n_current_language
      @lcase.keyword = params[:lcase][:keyword]
      @lcase.description = params[:lcase][:description]
      @lcase.native_name = params[:lcase][:native_name]
      @lcase.latin_name = params[:lcase][:latin_name]

      if @lcase.save
        trfn("Language case has been saved")
      else
        trfe(@lcase.errors.full_messages.first)
      end

      @lcase.language.update_cache

      return redirect_to(:action => :view, :id => @lcase.id) if @lcase.id
      return redirect_to(:action => :index)
    end
    render :layout => false
  end

  def delete_case
    lcase = Tr8n::LanguageCase.find_by_id(params[:id]) if params[:id]
    unless lcase
      trfe("Invalid context id")
      return redirect_back
    end

    lcase.destroy
    lcase.language.update_cache
    redirect_to(:action => :index)
  end

  def case_rule_modal
    Tr8n::Logger.debug(params.inspect)

    @lcase = Tr8n::LanguageCase.find_by_id(params[:id]) if params[:id]
    return render(:text => "Invalid context id") unless @lcase

    @position = (params[:position] || 0).to_i
    @case_rule = Tr8n::LanguageCaseRule.find_by_id(params[:rule_id]) if params[:rule_id]
    @case_rule ||= Tr8n::LanguageCaseRule.new(:definition => {})
    if request.post?
      @positions = @lcase.rules.collect{|rule| rule.id}

      @case_rule.language_case = @lcase
      @case_rule.description = params[:case_rule][:description]
      @case_rule.examples = params[:case_rule][:examples]
      @case_rule.definition ||= {}
      @case_rule.definition["conditions"] = params[:case_rule][:conditions]
      @case_rule.definition["conditions_expression"] = Tr8n::RulesEngine::Parser.new(@case_rule.definition["conditions"]).parse
      @case_rule.definition["operations"] = params[:case_rule][:operations]
      @case_rule.definition["operations_expression"] = Tr8n::RulesEngine::Parser.new(@case_rule.definition["operations"]).parse

      if @case_rule.save
        @positions.insert(@position, @case_rule.id)
        order_rules_by_positions(@positions)
        trfn("Rule has been saved")
      else
        trfe(@case_rule.errors.full_messages.first)
      end

      return redirect_to(:action => :view, :id => @lcase.id)
    end
    render :layout => false
  end

  def delete_case_rule
    case_rule = Tr8n::LanguageCaseRule.find_by_id(params[:rule_id]) if params[:rule_id]
    unless case_rule
      trfe("Invalid rule")
      return redirect_back
    end

    case_rule.destroy
    redirect_back
  end

  def update_rules_order
    order_rules_by_positions(params[:rules])
    render :nothing => true
  end

private

  def order_rules_by_positions(positions)
    positions.each_with_index do |id, index|
      Tr8n::LanguageCaseRule.update_all({:position => index+1}, {:id => id})
    end
  end
end
