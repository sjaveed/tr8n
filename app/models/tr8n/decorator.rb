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
#-- Tr8n::ApplicationLanguage Schema Information
#
# Table name: tr8n_application_languages
#
#  id                INTEGER     not null, primary key
#  application_id    integer     not null
#  feature_id        integer     not null
#  created_at        datetime    not null
#  updated_at        datetime    not null
#
# Indexes
#
#  tr8n_app_lang_app_id    (application_id)
#
#++

class Tr8n::Decorator < ActiveRecord::Base
  self.table_name = :tr8n_decorators

  attr_accessible :application, :css

  belongs_to :application

  serialize :css

  def self.find_or_create(app)
    where(:application_id => app.id).first || create(:application => app, :css => default_css)
  end

  def self.default_css
    css_options.first
  end

  def self.keys
    ["tr8n_not_translated", "tr8n_translated", "tr8n_fallback", "tr8n_locked", "tr8n_language_case"]
  end

  def self.css_options
    [
      {
          "tr8n_not_translated" => "border-bottom: 2px dotted red;",
          "tr8n_translated"     => "border-bottom: 2px dotted green;",
          "tr8n_fallback"       => "border-bottom: 2px dotted #e90;",
          "tr8n_locked"         => "border-bottom: 2px dotted blue;",
          "tr8n_language_case"  => "padding:3px; border: 1px dotted blue;",
      },
      {
          "tr8n_not_translated" => "border-bottom: 2px solid red;",
          "tr8n_translated"     => "border-bottom: 2px solid green;",
          "tr8n_fallback"       => "border-bottom: 2px solid #e90;",
          "tr8n_locked"         => "border-bottom: 2px solid blue;",
          "tr8n_language_case"  => "padding:3px; border: 1px dotted blue;",
      },
      {
          "tr8n_not_translated" => "padding-bottom:3px; background: url(/assets/tr8n/lines/red1.png) repeat-x bottom;",
          "tr8n_translated"     => "padding-bottom:3px; background: url(/assets/tr8n/lines/green1.png) repeat-x bottom;",
          "tr8n_fallback"       => "padding-bottom:3px; background: url(/assets/tr8n/lines/yellow1.png) repeat-x bottom;",
          "tr8n_locked"         => "padding-bottom:3px; background: url(/assets/tr8n/lines/blue1.png) repeat-x bottom;",
          "tr8n_language_case"  => "padding:3px; border: 1px dotted blue;",
      },
      {
          "tr8n_not_translated" => "padding-bottom:3px; background: url(/assets/tr8n/lines/red3.png) repeat-x bottom;",
          "tr8n_translated"     => "padding-bottom:3px; background: url(/assets/tr8n/lines/green3.png) repeat-x bottom;",
          "tr8n_fallback"       => "padding-bottom:3px; background: url(/assets/tr8n/lines/yellow3.png) repeat-x bottom;",
          "tr8n_locked"         => "padding-bottom:3px; background: url(/assets/tr8n/lines/blue3.png) repeat-x bottom;",
          "tr8n_language_case"  => "padding:3px; border: 1px dotted blue;",
      },
      {
          "tr8n_not_translated" => "padding-bottom:3px; background: url(/assets/tr8n/lines/red2.png) repeat-x bottom;",
          "tr8n_translated"     => "padding-bottom:3px; background: url(/assets/tr8n/lines/green2.png) repeat-x bottom;",
          "tr8n_fallback"       => "padding-bottom:3px; background: url(/assets/tr8n/lines/yellow2.png) repeat-x bottom;",
          "tr8n_locked"         => "padding-bottom:3px; background: url(/assets/tr8n/lines/blue2.png) repeat-x bottom;",
          "tr8n_language_case"  => "padding:3px; border: 1px dotted blue;",
      },
      {
          "tr8n_not_translated" => "padding:3px; background: #FFD9E6 url(/assets/tr8n/lines/red3.png) repeat-x bottom;",
          "tr8n_translated"     => "padding:3px; background: #E0FFD9 url(/assets/tr8n/lines/green3.png) repeat-x bottom;",
          "tr8n_fallback"       => "padding:3px; background: #FFFCD9 url(/assets/tr8n/lines/yellow3.png) repeat-x bottom;",
          "tr8n_locked"         => "padding:3px; background: #D9EEFF url(/assets/tr8n/lines/blue3.png) repeat-x bottom;",
          "tr8n_language_case"  => "padding:3px; background: #D9EEFF; border: 1px dotted blue;",
      },
    ]
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
end
