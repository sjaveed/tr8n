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

class Tr8n::App::WizardsController < Tr8n::App::BaseController

  def register_application
    domains = params[:domains].split("\n")
    translators_emails = params[:translators].split(',')

    if Tr8n::TranslationDomain.where("name in (?)", domains).any?
      return render(:json => {"error" => "Application with this domain already exists. Please contact application administrator to be added to the application"}.to_json)
    end

    default_language = Tr8n::Language.by_locale(params[:default_locale])
    app = Tr8n::Application.create(:name => params[:name], :description => params[:description], :default_language => default_language)

    domains.each do |domain|
      Tr8n::TranslationDomain.create(:name => domain, :appliction => app)
    end

    app.add_language(default_language)
    params[:locales].each do |locale|
      app.add_language(Tr8n::Language.by_locale(locale))
    end

    translators_emails.each do |email|
      # TODO: generate translator join request
    end

    app.add_translator(tr8n_current_translator)

    session[:tr8n_selected_app_id] = app.id

    render(:json => {"status" => "ok"}.to_json)
  end

  def register_component
    domains = params[:domains].split("\n")
    translators_emails = params[:translators].split(',')

    if Tr8n::TranslationDomain.where("name in (?)", domains).any?
      return render(:json => {"error" => "Application with this domain already exists. Please contact application administrator to be added to the application"}.to_json)
    end

    default_language = Tr8n::Language.by_locale(params[:default_locale])
    app = Tr8n::Application.create(:name => params[:name], :description => params[:description], :default_language => default_language)

    domains.each do |domain|
      Tr8n::TranslationDomain.create(:name => domain, :appliction => app)
    end

    app.add_language(default_language)
    params[:locales].each do |locale|
      app.add_language(Tr8n::Language.by_locale(locale))
    end

    translators_emails.each do |email|
      # TODO: generate translator join request
    end

    app.add_translator(tr8n_current_translator)

    session[:tr8n_selected_app_id] = app.id

    render(:json => {"status" => "ok"}.to_json)
  end
end
