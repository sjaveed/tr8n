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
#-- Tr8n::Emails::Partial Schema Information
#
# Table name: tr8n_email_templates
#
#  id                integer                        not null, primary key
#  application_id    integer                        
#  language_id       integer                        
#  keyword           character varying(255)         
#  name              character varying(255)         
#  description       character varying(255)         
#  subject           character varying(255)         
#  html_body         text                           
#  tokens            text                           
#  created_at        timestamp without time zone    not null
#  updated_at        timestamp without time zone    not null
#  text_body         text                           
#  type              character varying(255)         
#  parent_id         integer                        
#  layout            character varying(255)         
#  version           integer                        
#  state             character varying(255)         
#
# Indexes
#
#  tr8n_et_t_a    (type, application_id, keyword) 
#
#++

class Tr8n::Emails::Partial < Tr8n::Emails::Base

  def title
    "Partial: #{keyword}"
  end

  def source_key
    "/emails/partials/#{keyword}"
  end

  def render_body(mode = :html, tokens = self.tokens, options = {})
    if Tr8n::RequestContext.email_render_options.blank?
      return super
    end

    tokens = Tr8n::RequestContext.current_application.tokens("data").merge(tokens)

    ::Liquid::Template.parse(content(mode)).render(tokens).html_safe
  end

end