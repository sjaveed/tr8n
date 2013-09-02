#--
# Copyright (c) 2010-2012 Michael Berkovich, tr8nhub.com
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

class Tr8n::Language::ContextRulesController < Tr8n::Language::BaseController

  def index

  end

  def view
    @context = Tr8n::LanguageContext.find_by_id(params[:id])
    unless @context
      trfe("Invalid context id")
      return redirect_to(:action => :index)
    end
  end

  def context_modal
    @context = Tr8n::LanguageContext.find_by_id(params[:id]) if params[:id]
    @context ||= Tr8n::LanguageContext.new(:definition => {"token_mapping" => []})
    if request.post? and params[:context]
      @context.language = tr8n_current_language
      @context.keyword = params[:context][:keyword]
      @context.description = params[:context][:description]
      @context.definition ||= {}
      @context.definition["token_expression"] = params[:context][:token_expression]
      @context.definition["variables"] = params[:context][:variables].split(',').collect{|v| v.strip}
      @context.definition["token_mapping"] = params[:context][:token_mapping].split("\r\n").collect do |tm|
        /^{/.match(tm) ? JSON.parse(tm) : tm
      end
      if @context.save
        trfn("Context has been saved")
      else
        trfe(@context.errors.full_messages.first)
      end
      return redirect_to(:action => :view, :id => @context.id) if @context.id
      return redirect_to(:action => :index)
    end
    render :layout => false
  end

  def delete_context
    context = Tr8n::LanguageContext.find_by_id(params[:id]) if params[:id]
    unless context
      trfe("Invalid context id")
      return redirect_back
    end

    context.destroy
    redirect_to(:action => :index)
  end

  def context_rule_modal
    @context = Tr8n::LanguageContext.find_by_id(params[:id]) if params[:id]
    return render(:text => "Invalid context id") unless @context

    @context_rule = Tr8n::LanguageContextRule.find_by_id(params[:rule_id]) if params[:rule_id]
    @context_rule ||= Tr8n::LanguageContextRule.new(:definition => {})
    if request.post?
      @context_rule.language_context = @context
      @context_rule.keyword = params[:context_rule][:keyword]
      @context_rule.description = params[:context_rule][:description]
      @context_rule.definition ||= {}
      @context_rule.definition["conditions"] = params[:context_rule][:conditions]
      @context_rule.examples = params[:context_rule][:examples]

      if @context_rule.save
        trfn("Context rule has been saved")
      else
        trfe(@context_rule.errors.full_messages.first)
      end

      return redirect_to(:action => :view, :id => @context.id)
    end
    render :layout => false
  end

  def delete_context_rule
    context_rule = Tr8n::LanguageContextRule.find_by_id(params[:rule_id]) if params[:rule_id]
    unless context_rule
      trfe("Invalid context rule")
      return redirect_back
    end

    context_rule.destroy
    redirect_back
  end
end
