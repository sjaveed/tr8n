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

  def application
    if request.post?
      domains = params[:domains].split("\n")
      translators_emails = params[:translators].split(',')

      if Tr8n::TranslationDomain.where("name in (?)", domains).any?
        return render(:json => {"error" => tra("Application with this domain already exists. Please contact application administrator to be added to the application")}.to_json)
      end

      default_language = Tr8n::Language.by_locale(params[:default_locale])
      app = Tr8n::Application.create(:name => params[:name], :description => params[:description], :default_language => default_language)

      domains.each do |domain|
        Tr8n::TranslationDomain.create(:name => domain, :application => app)
      end

      app.add_language(default_language)
      unless params[:locales].blank?
        params[:locales].each do |locale|
          app.add_language(Tr8n::Language.by_locale(locale))
        end
      end

      translators_emails.each do |email|
        # TODO: generate translator join request
      end

      app.add_translator(tr8n_current_translator)

      session[:tr8n_selected_app_id] = app.id

      return render(:json => {"status" => "Ok", "msg" => tra("[bold: {application}] was registered successfully.", :application => app.name)}.to_json)
    end

    render :layout => false
  end

  def component
    if request.post?
      component = Tr8n::Component.create(:application => selected_application, :name => params[:name], :description => params[:description])

      unless params[:locales].blank?
        params[:locales].each do |locale|
          component.add_language(Tr8n::Language.by_locale(locale))
        end
      end

      unless params[:sources].blank?
        params[:sources].each do |src_id|
          src = Tr8n::TranslationSource.find_by_id(src_id)
          component.add_source(src) if src
        end
      end

      #translators_emails = params[:translators].split(',')
      #translators_emails.each do |email|
      #  # TODO: generate translator join request
      #end

      component.add_translator(tr8n_current_translator)

      return render(:json => {"status" => "Ok", "msg" => tra("[bold: {component}] was registered successfully.", :component => component.name)}.to_json)
    end

    render :layout => false
  end

  def translation_key
    if request.post?
      src = Tr8n::TranslationSource.find_or_create("/manual_keys", selected_application)
      tkey = Tr8n::TranslationKey.find_or_create(params[:label], params[:description], {:locale => params[:default_locale], :source => src})

      unless params[:sources].blank?
        params[:sources].each do |src_id|
          src = Tr8n::TranslationSource.find_by_id(src_id)
          src.add_translation_key(tkey) if src
        end
      end

      return render(:json => {"status" => "Ok", "msg" => tra("The translation key has been registered successfully.")}.to_json)
    end

    render :layout => false
  end

  def email_template
    if request.post?
      Tr8n::Logger.debug(params.inspect)

      if Tr8n::EmailTemplate.where(:application_id => selected_application.id, :keyword => params[:keyword]).any?
        return render(:json => {"error" => tra("Template keyword must be unique")}.to_json)
      end

      default_language = Tr8n::Language.by_locale(params[:default_locale])
      Tr8n::EmailTemplate.create(:application => selected_application, :keyword => params[:keyword], :language => default_language,
                                       :name => params[:name], :description => params[:description],
                                       :subject => params[:subject], :body => params[:body])

      return render(:json => {"status" => "Ok", "msg" => tra("Email template has been registered")}.to_json)
    end

    render :layout => false
  end
end
