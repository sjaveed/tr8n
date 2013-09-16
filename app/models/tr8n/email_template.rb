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

class Tr8n::EmailTemplate < ActiveRecord::Base
  self.table_name = :tr8n_email_templates

  attr_accessible :application, :language, :keyword, :subject, :body, :tokens, :name, :description

  belongs_to :application, :class_name => 'Tr8n::Application'
  belongs_to :language, :class_name => 'Tr8n::Language'

  serialize :tokens

  def render_body(mode = :html, tokens = self.tokens, options = {})
    #if mode == :text
    #  content = self.text_body.to_s
    #else
    #  content = self.html_body.to_s
    #end

    Tr8n::Config.render_email_with_options(options.merge(:language => Tr8n::Config.current_language,
                                                         :tokens => tokens,
                                                         :options => {:source => "/emails/#{keyword}"},
        :mode => mode)) do
      @result = ::Liquid::Template.parse(self.body).render(tokens)
    end
    @result.html_safe
  end

  def render_subject(tokens = self.tokens, options = {})
    #s = Postoffice::EmailSubject.find_by_key(options[:subject]) if options[:subject]
    #if s and s.label
    #  content = s.label
    #else
    #  content = self.subject
    #end

    Tr8n::Config.render_email_with_options(options.merge(:language => Tr8n::Config.current_language,
                                                         :tokens => tokens,
                                                         :options => {:source => "/emails/#{keyword}"})) do
      @result = ::Liquid::Template.parse(self.subject).render(tokens)
    end
    @result.html_safe
  end


end
