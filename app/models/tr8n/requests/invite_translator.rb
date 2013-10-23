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
#-- Tr8n::Requests::TranslatorApplication Schema Information
#
# Table name: tr8n_requests
#
#  id                INTEGER         not null, primary key
#  type              varchar(255)    
#  state             varchar(255)    
#  key               varchar(255)    
#  email             varchar(255)    
#  from_id           integer         
#  to_id             integer         
#  data              text            
#  expires_at        datetime        
#  created_at        datetime        not null
#  updated_at        datetime        not null
#  application_id    integer         
#
# Indexes
#
#  tr8n_req_t_a_e                                   (type, application_id, email) 
#  index_tr8n_requests_on_to_id                     (to_id) 
#  index_tr8n_requests_on_from_id                   (from_id) 
#  index_tr8n_requests_on_type_and_key_and_state    (type, key, state) 
#
#++

class Tr8n::Requests::InviteTranslator < Tr8n::Requests::Base

  data_attributes :locales, :message

  def email_tokens
    hash = {
        "user"                  => from.name,
        "application"           => application.name,
        "application_logo_url"  => application.logo_url,
        "languages"             => language_names,
        "link"                  => lander_url
    }
    hash["message"] = message unless message.blank?
    hash
  end

  def accept(user)
    update_attributes(:to => user)
    application.add_translator(Tr8n::Translator.find_or_create(user))
    mark_as_accepted!
  end

  def languages
    return [] unless locales
    @languages ||= locales.collect{|locale| Tr8n::Language.by_locale(locale)}
  end

  def language_names
    @language_names ||= languages.collect{|l| l.english_name}
  end


end
