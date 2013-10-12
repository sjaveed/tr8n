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
#-- Tr8n::EmailTemplate Schema Information
#
# Table name: tr8n_email_templates
#
#  id                INTEGER         not null, primary key
#  application_id    integer
#  language_id       integer
#  keyword           varchar(255)
#  name              varchar(255)
#  description       varchar(255)
#  subject           varchar(255)
#  body              text
#  tokens            text
#  created_at        datetime        not null
#  updated_at        datetime        not null
#
# Indexes
#
#  index_tr8n_email_templates_on_application_id_and_keyword    (application_id, keyword)
#
#++

class Tr8n::Emails::Layout < Tr8n::Emails::Base

  def title
    "Layout: #{keyword}"
  end

  def source
    "/emails/layouts/#{keyword}"
  end

  def render_body(mode = :html, tokens = self.tokens, options = {})
    content = content(mode)

    options[:language] ||= Tr8n::RequestContext.current_language

    Tr8n::RequestContext.render_email_with_options(options.merge(:mode => mode, :tokens => tokens, :source => source)) do
      @result = ::Liquid::Template.parse(content).render(tokens)
    end

    if options[:yield]
      @result = @result.gsub("{! yield !}", options[:yield])
    else
      @result = @result.gsub("{! yield !}", "[EMAIL CONTENT WILL GO HERE]")
    end

    @result.html_safe
  end

end