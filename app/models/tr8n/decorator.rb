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
#
#-- Tr8n::Decorator Schema Information
#
# Table name: tr8n_decorators
#
#  id                integer                        not null, primary key
#  application_id    integer                        
#  css               text                           
#  created_at        timestamp without time zone    not null
#  updated_at        timestamp without time zone    not null
#
# Indexes
#
#  tr8n_decors_app    (application_id) 
#
#++

class Tr8n::Decorator < ActiveRecord::Base
  self.table_name = :tr8n_decorators

  attr_accessible :application, :css

  belongs_to :application, :class_name => 'Tr8n::Application'

  serialize :css

  def self.find_or_create(app)
    where(:application_id => app.id).first || create(:application => app, :css => default_css)
  end

  def self.default_css
    css_options.first
  end

  def self.keys
    ["tr8n_not_translated", "tr8n_pending", "tr8n_translated", "tr8n_locked",  "tr8n_fallback", "tr8n_language_case"]
  end

  def self.css_options
    [
      {
          "tr8n_not_translated" => "border-bottom: 2px dotted red;",
          "tr8n_translated"     => "border-bottom: 2px dotted green;",
          "tr8n_fallback"       => "border-bottom: 2px dotted #e90;",
          "tr8n_locked"         => "border-bottom: 2px dotted blue;",
          "tr8n_pending"        => "border-bottom: 2px dotted #e90;",
          "tr8n_language_case"  => "padding:3px; border: 1px dotted blue;",
      },
      {
          "tr8n_not_translated" => "border-bottom: 2px solid red;",
          "tr8n_translated"     => "border-bottom: 2px solid green;",
          "tr8n_fallback"       => "border-bottom: 2px solid #e90;",
          "tr8n_pending"        => "border-bottom: 2px solid #e90;",
          "tr8n_locked"         => "border-bottom: 2px solid blue;",
          "tr8n_language_case"  => "padding:3px; border: 1px dotted blue;",
      },
      {
          "tr8n_not_translated" => "padding-bottom:3px; background: url(#{Tr8n::Config.base_url}/assets/tr8n/lines/red1.png) repeat-x bottom;",
          "tr8n_translated"     => "padding-bottom:3px; background: url(#{Tr8n::Config.base_url}/assets/tr8n/lines/green1.png) repeat-x bottom;",
          "tr8n_fallback"       => "padding-bottom:3px; background: url(#{Tr8n::Config.base_url}/assets/tr8n/lines/yellow1.png) repeat-x bottom;",
          "tr8n_pending"        => "padding-bottom:3px; background: url(#{Tr8n::Config.base_url}/assets/tr8n/lines/yellow1.png) repeat-x bottom;",
          "tr8n_locked"         => "padding-bottom:3px; background: url(#{Tr8n::Config.base_url}/assets/tr8n/lines/blue1.png) repeat-x bottom;",
          "tr8n_language_case"  => "padding:3px; border: 1px dotted blue;",
      },
      {
          "tr8n_not_translated" => "padding-bottom:3px; background: url(#{Tr8n::Config.base_url}/assets/tr8n/lines/red3.png) repeat-x bottom;",
          "tr8n_translated"     => "padding-bottom:3px; background: url(#{Tr8n::Config.base_url}/assets/tr8n/lines/green3.png) repeat-x bottom;",
          "tr8n_fallback"       => "padding-bottom:3px; background: url(#{Tr8n::Config.base_url}/assets/tr8n/lines/yellow3.png) repeat-x bottom;",
          "tr8n_pending"        => "padding-bottom:3px; background: url(#{Tr8n::Config.base_url}/assets/tr8n/lines/yellow3.png) repeat-x bottom;",
          "tr8n_locked"         => "padding-bottom:3px; background: url(#{Tr8n::Config.base_url}/assets/tr8n/lines/blue3.png) repeat-x bottom;",
          "tr8n_language_case"  => "padding:3px; border: 1px dotted blue;",
      },
      {
          "tr8n_not_translated" => "padding-bottom:3px; background: url(#{Tr8n::Config.base_url}/assets/tr8n/lines/red2.png) repeat-x bottom;",
          "tr8n_translated"     => "padding-bottom:3px; background: url(#{Tr8n::Config.base_url}/assets/tr8n/lines/green2.png) repeat-x bottom;",
          "tr8n_fallback"       => "padding-bottom:3px; background: url(#{Tr8n::Config.base_url}/assets/tr8n/lines/yellow2.png) repeat-x bottom;",
          "tr8n_pending"        => "padding-bottom:3px; background: url(#{Tr8n::Config.base_url}/assets/tr8n/lines/yellow2.png) repeat-x bottom;",
          "tr8n_locked"         => "padding-bottom:3px; background: url(#{Tr8n::Config.base_url}/assets/tr8n/lines/blue2.png) repeat-x bottom;",
          "tr8n_language_case"  => "padding:3px; border: 1px dotted blue;",
      },
      {
          "tr8n_not_translated" => "padding:3px; background: #FFD9E6 url(#{Tr8n::Config.base_url}/assets/tr8n/lines/red3.png) repeat-x bottom;",
          "tr8n_translated"     => "padding:3px; background: #E0FFD9 url(#{Tr8n::Config.base_url}/assets/tr8n/lines/green3.png) repeat-x bottom;",
          "tr8n_fallback"       => "padding:3px; background: #FFFCD9 url(#{Tr8n::Config.base_url}/assets/tr8n/lines/yellow3.png) repeat-x bottom;",
          "tr8n_pending"        => "padding:3px; background: #FFFCD9 url(#{Tr8n::Config.base_url}/assets/tr8n/lines/yellow3.png) repeat-x bottom;",
          "tr8n_locked"         => "padding:3px; background: #D9EEFF url(#{Tr8n::Config.base_url}/assets/tr8n/lines/blue3.png) repeat-x bottom;",
          "tr8n_language_case"  => "padding:3px; background: #D9EEFF; border: 1px dotted blue;",
      },
    ]
  end

  def classes
    cls = application.feature_enabled?(:decorations) ? css : self.class.default_css
    css = [];
    cls.each do |name, value|
      css << ".#{name} { #{value} }"
      #css << ".#{name} p { #{value} }"
      #css << ".#{name} h1 { #{value} }"
      #css << ".#{name} h2 { #{value} }"
      #css << ".#{name} h3 { #{value} }"
    end
    css.join(' ').gsub("\n", ' ').gsub("\r", ' ').html_safe
  end

  def css_tag
    html = ["<style>"]
    cls = application.feature_enabled?(:decorations) ? css : self.class.default_css
    cls.each do |name, value|
      html << ".#{name} { #{value} }"
    end
    html << "</style>"
    html.join(" ").html_safe
  end

  def select(index)
    update_attributes(:css => self.class.css_options[index.to_i])
  end

  def decorate_translation(language, translation_key, translated_label, options = {})
    return translated_label if options[:skip_decorations]
    return translated_label if translation_key.language == Tr8n::RequestContext.current_language
    return translated_label if Tr8n::RequestContext.current_user_is_guest?

    return translated_label unless Tr8n::RequestContext.current_user_is_translator?
    return translated_label if Tr8n::RequestContext.current_translator.blocked?
    return translated_label unless Tr8n::RequestContext.current_translator.enable_inline_translations?
    return translated_label unless Tr8n::RequestContext.current_translator.level >= Tr8n::RequestContext.current_application.translator_level
    return translated_label unless Tr8n::RequestContext.current_translator.level >= translation_key.level

    locked = translation_key.locked?(language)
    return translated_label if locked and not Tr8n::RequestContext.current_translator.manager?

    classes = ['tr8n_translatable']

    if locked
      classes << 'tr8n_locked'
    elsif language.default?
      classes << 'tr8n_not_translated'
    elsif options[:fallback]
      classes << 'tr8n_fallback'
    elsif options[:translated]
      if translation_key.label == translated_label
        classes << 'tr8n_pending'
      else
        classes << 'tr8n_translated'
      end
    else
      classes << 'tr8n_not_translated'
    end

    html = ["<span class='#{classes.join(' ')}' data-translation_key_id='#{translation_key.id}'>"]
    html << translated_label
    html << "</span>"
    html.join('')
  end

  def decorate_translation_key(language, translation_key, options = {})
    sanitized_label = translation_key.sanitized_label
    return sanitized_label if Tr8n::RequestContext.current_user_is_guest?
    return sanitized_label unless Tr8n::RequestContext.current_user_is_translator?
    return sanitized_label unless translation_key.can_be_translated?
    return sanitized_label if translation_key.locked?(language)

    classes = ['tr8n_translatable']

    if translation_key.cached_translations_for_language(language).any?
      classes << 'tr8n_translated'
    else
      classes << 'tr8n_not_translated'
    end

    html = "<span class='#{classes.join(' ')}' data-translation_key_id='#{translation_key.id}'>"
    html << ERB::Util.html_escape(sanitized_label)
    html << "</span>"
    html.html_safe
  end

end
