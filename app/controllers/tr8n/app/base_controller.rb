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

class Tr8n::App::BaseController < Tr8n::BaseController

  before_filter :validate_current_translator
  before_filter :validate_selected_application

private

  def selected_application
    @selected_application ||= Tr8n::Application.find_by_id(session[:tr8n_selected_app_id])
  end
  helper_method :selected_application

  def validate_selected_application
    if params[:app_id]
      @selected_application = Tr8n::Application.find_by_id(params[:app_id])

      unless @selected_application
        @selected_application = tr8n_current_translator.applications.first
        trfe("Invalid application id")
      end

      session[:tr8n_selected_app_id] = @selected_application.id
    elsif session[:tr8n_selected_app_id]
      @selected_application = Tr8n::Application.find_by_id(session[:tr8n_selected_app_id])
    end

    unless @selected_application
      if tr8n_current_translator.applications.empty?
        Tr8n::RequestContext.container_application.add_translator(tr8n_current_translator)
      end
      @selected_application = tr8n_current_translator.applications.first
      session[:tr8n_selected_app_id] = @selected_application.id
    end

    unless tr8n_current_user_is_admin?
      unless tr8n_current_translator.applications.include?(@selected_application)
        trfe("You are not authorized to view this application")
        @selected_application = tr8n_current_translator.applications.first
        session[:tr8n_selected_app_id] = @selected_application.id
      end
    end
  end

  def translator_applications
    tr8n_current_translator.applications
  end
  helper_method :translator_applications

  def application_admin?
    tr8n_current_user.admin?
  end
  helper_method :application_admin?

end
