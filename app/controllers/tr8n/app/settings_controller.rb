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

class Tr8n::App::SettingsController < Tr8n::App::BaseController

  def index

  end

  def basics
    if request.post?
      selected_application.name = params[:application][:name]
      selected_application.description = params[:application][:description]
      selected_application.save
      trfn("Application has been updated")
    end
  end

  def set_default_language
    selected_application.default_language = Tr8n::Language.by_locale(params["default_locale"])
    selected_application.save
    redirect_back
  end

  def decorations
  end

  def select_decoration
    selected_application.decorator.select(params[:index])
    redirect_back
  end

  def decoration_modal
    @style = selected_application.decorator.css[params[:key]]

    if request.post?
      selected_application.decorator.css[params[:key]] = params[:style]
      selected_application.decorator.save
      trfn("Style has been updated")
      return redirect_to(:action => :decorations)
    end

    render :layout => false
  end

  def shortcuts
  end

  def shortcut_modal
    @shortcut = selected_application.shortcuts[params[:keys]] if params[:keys]
    @shortcut ||= {}

    @shortcut["keys"] = params[:keys]

    if request.post?
      selected_application.shortcuts.delete(params[:keys]) if params[:keys]
      selected_application.shortcuts[params[:shortcut][:keys]] = {
          "description" => params[:shortcut][:description],
          "script" => params[:shortcut][:script],
      }
      selected_application.save
      trfn("Shortcut has been updated")
      return redirect_to(:action => :shortcuts)
    end

    render :layout => false
  end

  def delete_shortcut
    selected_application.shortcuts.delete(params[:keys])
    selected_application.save
    return redirect_to(:action => :shortcuts)
  end

  def generate_secret
    selected_application.reset_secret!
    redirect_back
  end

  def features
  end

  def toggle_feature
    selected_application.toggle_feature(params[:key], params[:flag] == "true")
    render :text => {"result" => "Ok"}.to_json
  end

  def languages

  end

  def add_languages_modal
    if request.post?
      params[:locales].split(',').each do |locale|
        selected_application.add_language(Tr8n::Language.by_locale(locale))
      end
      return redirect_to(:action => :languages)
    end

    render :layout => false
  end

  def remove_language
    selected_application.remove_language(Tr8n::Language.by_locale(params[:locale]))
    redirect_back
  end

  def update_languages_order
    params[:languages].each_with_index do |id, index|
      Tr8n::ApplicationLanguage.update_all({:position => index+1}, {:id => id})
    end

    render :nothing => true
  end

end
