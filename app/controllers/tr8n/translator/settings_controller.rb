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

class Tr8n::Translator::SettingsController < Tr8n::Translator::BaseController

  def index
    @translator = Tr8n::Config.current_translator
    @fallback_language = (tr8n_current_translator.fallback_language || tr8n_default_language)

    if request.post?
      tr8n_current_translator.update_attributes(params[:translator])
      tr8n_current_translator.reload

      trfn("Your information has been updated")
      @fallback_language = (tr8n_current_translator.fallback_language || tr8n_default_language)
    end
  end

  def generate_access_key
    Tr8n::Config.current_translator.generate_access_key!
    trfn("New access key has be generated")
    redirect_to_source
  end

  def features
  end

  def toggle_feature
    tr8n_current_translator.toggle_feature(params[:key], params[:flag] == "true")
    render :text => {"result" => "Ok"}.to_json
  end

  def languages

  end

  def add_languages_modal
    if request.post?
      params[:locales].split(',').each do |locale|
        tr8n_current_translator.add_language(Tr8n::Language.by_locale(locale))
      end
      return redirect_to(:action => :languages)
    end

    render :layout => false
  end

  def remove_language
    tr8n_current_translator.remove_language(Tr8n::Language.by_locale(params[:locale]))
    redirect_back
  end

  def update_languages_order
    params[:languages].each_with_index do |id, index|
      Tr8n::TranslatorLanguage.update_all({:position => index+1}, {:id => id})
    end

    render :nothing => true
  end

end
