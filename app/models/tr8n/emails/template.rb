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
#-- Tr8n::Emails::Template Schema Information
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

class Tr8n::Emails::Template < Tr8n::Emails::Base

  def title
    "Email: #{keyword}"
  end

  def email_layout
    @email_layout ||= (Tr8n::Emails::Layout.find_by_keyword(layout) unless layout.nil?)
  end

  def render_body(mode = :html, tokens = {}, options = {})
    options[:language] ||= Tr8n::RequestContext.current_language

    #tokens = self.tokens.merge(tokens)
    tokens = Tr8n::RequestContext.current_application.tokens("data").merge(tokens)

    Tr8n::RequestContext.render_email_with_options(options.merge(:mode => mode, :tokens => tokens, :source => source_key)) do
      @result = ::Liquid::Template.parse(content(mode)).render(tokens)
    end

    return @result.html_safe unless email_layout

    email_layout.render_body(mode, tokens, options.merge(:yield => @result))
  end

end