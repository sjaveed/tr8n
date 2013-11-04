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

module Tr8n
  module ActionViewExtension
    extend ActiveSupport::Concern

    def tr8n_options_for_select(options, selected = nil, description = nil)
      options_for_select(options.tro(description), selected)
    end

    def tr8n_phrases_link_tag(search = "", phrase_type = :without, phrase_status = :any)
      return unless Tr8n::Config.enabled?
      return if Tr8n::RequestContext.current_language.default?
      return unless Tr8n::RequestContext.current_user_is_translator?
      return unless Tr8n::RequestContext.current_translator.enable_inline_translations?

      link_to(image_tag("tr8n/translate_icn.gif", :style => "vertical-align:middle; border: 0px;", :title => search), 
             :controller => "/tr8n/app/phrases", :action => :index,
             :search => search, :phrase_type => phrase_type, :phrase_status => phrase_status).html_safe
    end

    def tr8n_language_flag_tag(lang = Tr8n::RequestContext.current_language, opts = {})
      return "" unless Tr8n::RequestContext.current_application.feature_enabled?(:language_flags)
      return "" unless lang
      html = image_tag(lang.flag_url, :style => "vertical-align:middle;", :title => lang.native_name)
      html << "&nbsp;".html_safe 
      html.html_safe
    end

    def tr8n_language_name_tag(lang = Tr8n::RequestContext.current_language, opts = {})
      return "" unless lang
      show_flag = opts[:flag].nil? ? true : opts[:flag]
      name_type = opts[:name].nil? ? :full : opts[:name] # :full, :native, :english, :locale
      linked = opts[:linked].nil? ? true : opts[:linked] 

      html = "<span style='white-space: nowrap'>"
      html << tr8n_language_flag_tag(lang, opts) if show_flag
      html << "<span dir='ltr'>"

      name = case name_type
        when :native  then lang.native_name
        when :english then lang.english_name
        when :locale  then lang.locale
        else lang.full_name
      end

      name ||= lang.english_name

      if linked
        html << link_to(name.html_safe, {:locale => lang.locale})
      else    
        html << name
      end

      html << "</span></span>"
      html.html_safe
    end

    def tr8n_language_strip_tag(opts = {})
      opts[:flag] = opts[:flag].nil? ? false : opts[:flag]
      opts[:name] = opts[:name].nil? ? :native : opts[:name] 
      opts[:linked] = opts[:linked].nil? ? true : opts[:linked] 
      opts[:javascript] = opts[:javascript].nil? ? false : opts[:javascript] 

      render(:partial => '/tr8n/common/language_strip', :locals => {:opts => opts})    
    end

    def tr8n_flashes_tag(opts = {})
      render(:partial => '/tr8n/common/flashes', :locals => {:opts => opts})    
    end

    def tr8n_scripts_tag(opts = {})
      render(:partial => '/tr8n/common/scripts', :locals => {:opts => opts})    
    end

    def tr8n_translator_rank_tag(translator, rank = nil, opts = {})
      return "" unless translator

      rank ||= translator.rank || 0

      style = opts[:style] || ""

      html = "<span dir='ltr'>"
      1.upto(5) do |i|
        if rank > i * 20 - 10  and rank < i * 20  
          html << image_tag("tr8n/rating_star05.png", :style=>style)
        elsif rank < i * 20 - 10 
          html << image_tag("tr8n/rating_star0.png", :style=>style)
        else
          html << image_tag("tr8n/rating_star1.png", :style=>style)
        end 
      end
      html << "</span>"
      html.html_safe    
    end

    def tr8n_help_icon_tag(wiki = "Home")
      link_to("<i class='icon-question-sign'></i>".html_safe, "http://wiki.tr8nhub.com/index.php?title=#{wiki}",
              :target => "_new",
              :style => "margin:5px;",
              "data-placement" => "bottom",
              "data-original-title" => "Click on the icon to go to the wiki site",
              "title" => "Click on the icon to go to the wiki site",
              "data-toggle" => "tooltip")
    end

    def tr8n_spinner_tag(id = "spinner", label = nil, cls='spinner')
      html = "<div id='#{id}' class='#{cls}' style='display:none'>"
      html << image_tag("tr8n/spinner.gif", :style => "vertical-align:middle;")
      html << " #{tr(label)}" if label
      html << "</div>"
      html.html_safe
    end

    def tr8n_toggler_tag(content_id, label = "", open = true)
      html = "<span id='#{content_id}_open' "
      html << "style='display:none'" unless open
      html << ">"
      html << link_to_function("#{image_tag("tr8n/arrow_down.gif", :style=>'text-align:center; vertical-align:middle')} #{label}".html_safe, "Tr8n.Utils.Effects.hide('#{content_id}_open'); Tr8n.Utils.Effects.show('#{content_id}_closed'); Tr8n.Utils.Effects.blindUp('#{content_id}');", :style=> "text-decoration:none")
      html << "</span>" 
      html << "<span id='#{content_id}_closed' "
      html << "style='display:none'" if open
      html << ">"
      html << link_to_function("#{image_tag("tr8n/arrow_right.gif", :style=>'text-align:center; vertical-align:middle')} #{label}".html_safe, "Tr8n.Utils.Effects.show('#{content_id}_open'); Tr8n.Utils.Effects.hide('#{content_id}_closed'); Tr8n.Utils.Effects.blindDown('#{content_id}');", :style=> "text-decoration:none")
      html << "</span>" 
      html.html_safe
    end  

    def tr8n_user_tag(user, options = {})
      return "Deleted User" unless user

      if options[:linked]
        link_to(user.name, user.link).html_safe
      else
        user.name
      end
    end

    def tr8n_user_mugshot_tag(translator, options = {})
      if translator and !translator.mugshot.blank?
        img_url = translator.mugshot
      else
        img_url = Tr8n::Config.silhouette_image
      end

      width = options[:width] || 48

      img_tag = "<img src='#{img_url}' style='width:#{width}px; padding:2px; border:1px solid #ccc;'>".html_safe

      if translator and options[:linked]
        link_to(img_tag, translator.link).html_safe
      else
        img_tag.html_safe
      end
    end

    def tr8n_translator_tag(translator, options = {})
      return "Deleted Translator" unless translator

      if options[:linked]
        link_to(translator.name, :controller => "/tr8n/translator/dashboard", :action => :index, :id => translator.id).html_safe
      else
        translator.name
      end
    end

    def tr8n_translator_mugshot_tag(translator, options = {})
      if translator and !translator.mugshot.blank?
        img_url = translator.mugshot
      else
        img_url = Tr8n::Config.silhouette_image
      end

      img_tag = "<img src='#{img_url}' style='width:48px'>"

      if translator and options[:linked]
        link_to(img_tag.html_safe, translator.url, :target => "_new").html_safe
      else
        img_tag.html_safe
      end
    end

    def tr8n_select_month(date, options = {}, html_options = {})
      month_names = options[:use_short_month] ? Tr8n::Config.default_abbr_month_names : Tr8n::Config.default_month_names
      select_month(date, options.merge(
        :use_month_names => month_names.collect{|month_name| Tr8n::Language.translate(month_name, options[:description] || "Month name")} 
      ), html_options)
    end

    def tr8n_paginator_tag(collection, options = {})
      render :partial => "/tr8n/common/paginator", :locals => {:collection => collection, :options => options}
    end

    def tr8n_with_options_tag(opts, &block)
      if Tr8n::Config.disabled?
        return capture(&block) if block_given?
        return ""
      end

      Thread.current[:tr8n_block_options] ||= []   
      Thread.current[:tr8n_block_options].push(opts)

      component = Tr8n::RequestContext.current_component_from_block_options
      if component
        source = Tr8n::RequestContext.current_source_from_block_options
        unless source.nil?
          Tr8n::ComponentSource.find_or_create(component, source)
        end
      end

      if Tr8n::RequestContext.current_user_is_authorized_to_view_component?(component)
        selected_language = Tr8n::RequestContext.current_language
        
        unless Tr8n::RequestContext.current_user_is_authorized_to_view_language?(component, selected_language)
          Tr8n::RequestContext.set_current_language(Tr8n::Config.default_language)
        end

        if block_given?
          ret = capture(&block) 
        end

        Tr8n::RequestContext.set_current_language(selected_language)
      else
        ret = ""
      end

      Thread.current[:tr8n_block_options].pop
      ret
    end

    def tr8n_content_for_locales_tag(opts = {}, &block)
      locale = Tr8n::RequestContext.current_language.locale

      if opts[:only] 
         return unless opts[:only].include?(locale)
      end

      if opts[:except]
        return if opts[:except].include?(locale)
      end

      if block_given?
        ret = capture(&block) 
      end
      ret
    end

    def tr8n_content_for_countries_tag(opts = {}, &block)
      country = Tr8n::Config.country_from_ip(tr8n_request_remote_ip)
      
      if opts[:only] 
         return unless opts[:only].include?(country)
      end

      if opts[:except]
        return if opts[:except].include?(country)
      end

      if block_given?
        ret = capture(&block) 
      end
      ret
    end

    ######################################################################
    ## Language Direction Support
    ######################################################################

    def tr8n_style_attribute_tag(attr_name = 'float', default = 'right', lang = Tr8n::RequestContext.current_language)
      "#{attr_name}:#{lang.align(default)}".html_safe
    end

    def tr8n_style_directional_attribute_tag(attr_name = 'padding', default = 'right', value = '5px', lang = Tr8n::RequestContext.current_language)
      "#{attr_name}-#{lang.align(default)}:#{value}".html_safe
    end

    def tr8n_dir_attribute_tag(lang = Tr8n::RequestContext.current_language)
      "dir='#{lang.dir}'".html_safe
    end

    def tr8n_when_string_tag(time, opts = {})
      elapsed_seconds = Time.now - time
      return tr('In the future, Marty!')  if elapsed_seconds < 0
      return tr('a moment ago', 'Time reference') if elapsed_seconds < 2.minutes

      if elapsed_seconds < 55.minutes
        elapsed_minutes = (elapsed_seconds / 1.minute).to_i
        return tr("{minutes||minute} ago", 'Time reference', :minutes => elapsed_minutes)
      end

      if elapsed_seconds < 1.75.hours
        return tr("about an hour ago", 'Time reference')
      end

      if elapsed_seconds < 12.hours
        elapsed_hours = (elapsed_seconds / 1.hour).to_i
        return tr("{hours||hour} ago", 'Time reference', :hours => elapsed_hours)
      end

      # elsif time.today_in_time_zone?
      #   display_time(time, :time_am_pm)
      # elsif time.yesterday_in_time_zone?
      #   tr("Yesterday at {time}", 'Time reference', :time => time.tr(:time_am_pm).gsub('/ ', '/').sub(/^[0:]*/,""))
      # elsif elapsed_seconds < 5.days
      #   time.tr(:day_time).gsub('/ ', '/').sub(/^[0:]*/,"")
      # elsif time.same_year_in_time_zone?
      #   time.tr(:monthname_abbr_time).gsub('/ ', '/').sub(/^[0:]*/,"")

      time.tr(:monthname_abbr_year).gsub('/ ', '/').sub(/^[0:]*/,"")
    end

    def tr8n_actions_tag(actions, opts = {}) 
      opts[:separator] ||= ' | '
      actions.join(opts[:separator]).html_safe
    end

    def tr8n_lightbox_header_tag(opts = {})
      render(:partial => "/tr8n/common/lightbox_header")
    end

    def tr8n_lightbox_footer_tag(opts = {})
      render(:partial => "/tr8n/common/lightbox_footer")
    end

    def tr8n_lightbox_title_tag(title, opts = {})
      render(:partial => "/tr8n/common/lightbox_title", :locals => {:title => title})
    end

  end
end
