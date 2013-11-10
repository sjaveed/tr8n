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

class Tr8n::App::TranslatorsController < Tr8n::App::BaseController

  before_filter :validate_application_management

  def index
    @translators = selected_application.translators.page(page).per(per_page)
  end

  def invitations
    @invitations = Tr8n::Requests::InviteTranslator.where(:application_id => selected_application.id).order("created_at desc").page(page).per(per_page)
  end

  def promote
    app_translator = tr8n_selected_application.application_translators.where(:translator_id => params[:id]).first
    if app_translator
      app_translator.manager = true
      app_translator.save
      trfn("Translator has been promoted to be application manager")
    end
    redirect_back
  end

  def demote
    app_translator = tr8n_selected_application.application_translators.where(:translator_id => params[:id]).first
    if app_translator
      app_translator.manager = false
      app_translator.save
      trfn("Translator has been demoted")
    end
    redirect_back
  end

  def invite_wizard
    if request.post?
      emails = params[:emails].strip.blank? ? [] : params[:emails].split(",")
      languages = params[:languages] unless params[:languages].blank?
      message = params[:message]

      emails.each do |email|
        user = Tr8n::Config.user_class.find_by_email(email)
        translator = Tr8n::Translator.by_user(user) if user
        next if user == tr8n_current_user
        next if translator and Tr8n::ApplicationTranslator.by_application_and_translator(selected_application, translator)

        req = Tr8n::Requests::InviteTranslator.where(:application_id => selected_application.id, :email => email).first
        req ||= Tr8n::Requests::InviteTranslator.create(:application_id => selected_application.id, :email => email)
        req.from=tr8n_current_user
        req.to=user
        req.locales=languages
        req.message=message
        req.save_and_deliver
      end

      return render(:json => {"status" => "Ok", "msg" => tra("Translators have been invited")}.to_json)
    end

    render :layout => false
  end

  def remove
    at = Tr8n::ApplicationTranslator.where(:application_id => selected_application.id, :translator_id => params[:id]).first

    if at
      trfn("Translator has been removed from the application")
      at.destroy
    end

    redirect_back
  end

  def view
    translator
  end

  def activity
    @activities = Tr8n::TranslatorLog.where(:translator_id => translator.id).page(page).per(per_page)
  end

  def translations
    @translations = Tr8n::Translation.where(:translator_id => translator.id).page(page).per(per_page)
  end

  def votes
    @votes = Tr8n::TranslationVote.where(:translator_id => translator.id).page(page).per(per_page)
  end

  def locks
    @locks = Tr8n::TranslationKeyLock.where(:translator_id => translator.id).page(page).per(per_page)
  end

  def comments
    @comments = Tr8n::TranslationKeyComment.where(:translator_id => translator.id).page(page).per(per_page)
  end

  def messages
    @messages = Tr8n::Forum::Message.where(:translator_id => translator.id).page(page).per(per_page)
  end

  def assignments
    @assignments = Tr8n::ComponentTranslator.where(:translator_id => translator.id).page(page).per(per_page)
  end

private

  def translator
    @translator ||= Tr8n::Translator.find_by_id(params[:id])
  end

end
