#--
# Copyright (c) 2010-2013 Michael Berkovich, tr8nhub.com
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

class Tr8n::Admin::LanguageController < Tr8n::Admin::BaseController
  
  def index
    @results = Tr8n::Language.filter(:params => params, :filter => Tr8n::Filters::Language)
  end

  def view
    @lang = Tr8n::Language.find(params[:lang_id])

    klass = {
      :metrics => Tr8n::Metrics::Language,
      :context_rules => Tr8n::LanguageContextRule,
      :cases => Tr8n::LanguageCaseRule,
      :case_rules => Tr8n::LanguageCaseRule,
      :case_exceptions => Tr8n::LanguageCaseValueMap,
    }[params[:mode].to_sym] if params[:mode]
    klass ||= Tr8n::Metrics::Language

    filter = {"wf_c0" => "language_id", "wf_o0" => "is", "wf_v0_0" => @lang.id}
    extra_params = {:lang_id => @lang.id, :mode => params[:mode]}
    @results = klass.filter(:params => params.merge(filter))
    @results.wf_filter.extra_params.merge!(extra_params)
  end

  def enable
    params[:languages] = [params[:lang_id]] if params[:lang_id]
    if params[:languages]
      params[:languages].each do |lang_id|
        language = Tr8n::Language.find_by_id(lang_id)
        language.enable! if language
      end  
    end
    redirect_to_source
  end
  
  def disable
    params[:languages] = [params[:lang_id]] if params[:lang_id]
    if params[:languages]
      params[:languages].each do |lang_id|
        language = Tr8n::Language.find_by_id(lang_id)
        language.disable! if language
      end  
    end
    redirect_to_source
  end
    
  def charts
    
  end

  def metrics
    @metrics = Tr8n::LanguageMetric.filter(:params => params, :filter => Tr8n::LanguageMetricFilter)
  end

  def users
    @users = Tr8n::LanguageUser.filter(:params => params, :filter => Tr8n::LanguageUserFilter)
  end

  def calculate_metrics
    Tr8n::LanguageMetric.calculate_language_metrics
    redirect_to_source
  end

  def calculate_total_metrics
    Tr8n::LanguageMetric.calculate_total_metrics
    redirect_to_source
  end
  
  def rules
    @rules = Tr8n::LanguageRule.filter(:params => params, :filter => Tr8n::LanguageRuleFilter)
  end

  def cases
    @cases = Tr8n::LanguageCase.filter(:params => params, :filter => Tr8n::LanguageCaseFilter)
  end

  def language_modal
    @language = Tr8n::Language.find_by_id(params[:id]) unless params[:id].blank?
    @language ||= Tr8n::Language.new

    if request.post?
      if @language.id
        @language.update_attributes(params[:language])
      else
        @language = Tr8n::Language.create(params[:language])
        @language.reset!
      end
      return redirect_back
    end

    render_modal
  end

  def case_rules
    @case_rules = Tr8n::LanguageCaseRule.filter(:params => params, :filter => Tr8n::LanguageCaseRuleFilter)
  end
  
  def case_values
    @case_values = Tr8n::LanguageCaseValueMap.filter(:params => params, :filter => Tr8n::LanguageCaseValueMapFilter)
  end
  
  def lb_value_map
    @map = Tr8n::LanguageCaseValueMap.find_by_id(params[:map_id]) if params[:map_id]
    @map ||= Tr8n::LanguageCaseValueMap.new(:language => tr8n_current_language)
    
    render_lightbox
  end
  
  def delete_value_map
    map = Tr8n::LanguageCaseValueMap.find_by_id(params[:map_id]) if params[:map_id]
    map.destroy if map

    redirect_to(:action => :index)
  end
  
  
end
