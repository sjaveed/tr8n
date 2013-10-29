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

class Tr8n::App::EmailsController < Tr8n::App::BaseController

  skip_before_filter :validate_current_translator, :only => [:view, :track]
  skip_before_filter :validate_selected_application, :only => [:view, :track]
  skip_before_filter :validate_guest_user, :only => [:view, :track]

  def index
    @emails = selected_application.email_templates.page(page).per(per_page)
  end

  def partials
    @partials = selected_application.email_partials.page(page).per(per_page)
  end

  def layouts
    @layouts = selected_application.email_layouts.page(page).per(per_page)
  end

  def assets
    @assets = selected_application.email_assets.order("created_at desc").page(page).per(per_page)
  end

  def template
    @et = Tr8n::Emails::Base.find_by_id(params[:id])
    if request.post?
      if params[:email_template][:tokens].blank?
        params[:email_template][:tokens] = "{}"
      end
      params[:email_template][:tokens] = JSON.parse(params[:email_template][:tokens])
      @et.update_attributes(params[:email_template])
    end
  end

  def save_template
    #Tr8n::Logger.debug(params.inspect)

    et = Tr8n::Emails::Base.find_by_id(params[:id])
    et.keyword = params[:keyword]
    et.name = params[:name] if params[:name]
    et.description = params[:description] if params[:description]
    et.subject = params[:subject] if params[:subject]
    et.tokens = JSON.parse(params[:tokens]) if params[:tokens]
    et.html_body = params[:html_body] if params[:html_body]
    et.text_body = params[:text_body] if params[:text_body]

    if params[:layout]
      et.layout = params[:layout] == "-1" ? nil : params[:layout]
    end

    et.save
    render :json => {"status" => "Ok"}
  end

  def delete_template
    et = Tr8n::Emails::Base.find_by_id(params[:id]) if params[:id]
    et.destroy if et
    return redirect_to :action => :layouts if et.is_a?(Tr8n::Emails::Layout)
    return redirect_to :action => :partials if et.is_a?(Tr8n::Emails::Partial)
    redirect_to :action => :index
  end

  def send_modal
    if params[:keyword]
      @et = selected_application.email_templates.where(:keyword => params[:keyword]).first
    else
      @et = Tr8n::Emails::Template.find_by_id(params[:id])
    end

    if request.post?
      tokens = JSON.parse(params[:email][:tokens])
      emails = params[:email][:to].split(",")
      language = Tr8n::Language.by_locale(params[:email][:language])

      emails.each do |email|
        Tr8n::Mailer.deliver(selected_application, @et.keyword, email, tokens, :language => language)
      end

      trfn("Email has been sent")
      return redirect_to(:action => :template, :id => @et.id)
    end

    render :layout => false
  end

  def upload_asset
    files = []

    params[:files].each do |file|
      asset = Tr8n::Emails::Asset.create_from_file(selected_application, file.original_filename, File.read(file.tempfile))
      files << {
          "name"=> file.original_filename,
          #"size"=> 902604,
          #"url"=> "http:\/\/example.org\/files\/picture1.jpg",
          #"thumbnailUrl"=> "http:\/\/example.org\/files\/thumbnail\/picture1.jpg",
          #"deleteUrl"=> "http:\/\/example.org\/files\/picture1.jpg",
          #"deleteType"=> "DELETE"
      }
    end

    render :json => {"files" => files}
  end

  def delete_asset
    asset = Tr8n::Emails::Asset.find_by_id(params[:id])
    asset.destroy if asset
    redirect_back
  end

  def asset_modal
    @asset = Tr8n::Emails::Asset.find_by_id(params[:id])

    if request.post?
      @asset.keyword = params[:asset][:keyword]
      @asset.save
      trfn("Asset has been updated")
      return redirect_to(:action => :assets)
    end

    render :layout => false
  end

  def email_template_wizard
    if request.post?
      if Tr8n::Emails::Template.where(:application_id => selected_application.id, :keyword => params[:keyword]).any?
        return render(:json => {"error" => tra("Template keyword must be unique")}.to_json)
      end

      default_language = Tr8n::Language.by_locale(params[:default_locale])
      Tr8n::Emails::Template.create(:application => selected_application, :keyword => params[:keyword], :language => default_language,
                                    :name => params[:name], :description => params[:description],
                                    :subject => params[:subject], :html_body => params[:html_body], :text_body => params[:text_body])

      return render(:json => {"status" => "Ok", "msg" => tra("Email template has been created")}.to_json)
    end

    render :layout => false
  end

  def email_partial_wizard
    if request.post?
      if Tr8n::Emails::Partial.where(:application_id => selected_application.id, :keyword => params[:keyword]).any?
        return render(:json => {"error" => tra("Partial keyword must be unique")}.to_json)
      end

      default_language = Tr8n::Language.by_locale(params[:default_locale])
      Tr8n::Emails::Partial.create(:application => selected_application, :keyword => params[:keyword], :language => default_language,
                                   :name => params[:name], :description => params[:description],
                                   :subject => params[:subject], :html_body => params[:html_body], :text_body => params[:text_body])

      return render(:json => {"status" => "Ok", "msg" => tra("Email partial has been created")}.to_json)
    end

    render :layout => false
  end

  def email_layout_wizard
    if request.post?
      default_language = Tr8n::Language.by_locale(params[:default_locale])
      Tr8n::Emails::Layout.create(:application => selected_application, :language => default_language,
                                  :name => params[:name], :description => params[:description],
                                  :subject => params[:subject], :html_body => params[:html_body], :text_body => params[:text_body])

      return render(:json => {"status" => "Ok", "msg" => tra("Email layout has been created")}.to_json)
    end

    render :layout => false
  end

  def preview
    if params[:keyword]
      @et = selected_application.email_templates.where(:keyword => params[:keyword]).first
    else
      @et = Tr8n::Emails::Base.find_by_id(params[:id])
    end

    @title = "Preview #{@et.title} (#{params[:mode]} mode)"
    @subject = @et.render_subject
    @body = @et.render_body(params[:mode])

    if params[:mode] == "text"
      @body = @body.gsub("\n", "<br>").html_safe
    end

    render :layout => "/tr8n/emails/translate"
  end

  def view
    log = Tr8n::Emails::Log.find_by_key(params[:id])
    unless log
      trfe("Email information was not found")
      return redirect_to_site_default_url
    end

    @et = log.email_template
    @from =

    @title = @et.title
    @subject = @et.render_subject
    @body = @et.render_body(:html, log.tokens)

    render :layout => "/tr8n/emails/translate"
  end

  def track
    log = Tr8n::Emails::Log.find_by_id(params[:id]) if params[:id]
    log.update_attributes(:viewed_at => Time.now) if log
    image_path = File.expand_path("#{__FILE__}/../../../../assets/images/tr8n/pixel.gif")
    data = File.open(image_path, "rb").read
    response.headers['Cache-Control'] = "public, max-age=#{12.hours.to_i}"
    response.headers['Content-Type'] = 'image/gif'
    response.headers['Content-Disposition'] = 'inline'
    render :text => data
  end

end