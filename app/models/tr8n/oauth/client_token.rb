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
#-- Tr8n::Oauth::ClientToken Schema Information
#
# Table name: tr8n_oauth_tokens
#
#  id                INTEGER         not null, primary key
#  type              varchar(255)    
#  token             varchar(255)    not null
#  application_id    integer         
#  translator_id     integer         
#  scope             varchar(255)    
#  expires_at        datetime        
#  created_at        datetime        not null
#  updated_at        datetime        not null
#
# Indexes
#
#  tr8n_oauth_tokens_trn_id    (translator_id) 
#  tr8n_oauth_tokens_app_id    (application_id) 
#
#++

class Tr8n::Oauth::ClientToken < Tr8n::Oauth::OauthToken

  def code
    token
  end

end
