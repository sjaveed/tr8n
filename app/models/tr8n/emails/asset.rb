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
#-- Tr8n::Emails::Asset Schema Information
#
# Table name: tr8n_media
#
#  id            integer                        not null, primary key
#  type          character varying(255)         
#  position      integer                        
#  owner_id      integer                        
#  owner_type    character varying(255)         
#  keyword       character varying(255)         
#  path          character varying(255)         
#  thumbnails    text                           
#  created_at    timestamp without time zone    not null
#  updated_at    timestamp without time zone    not null
#
# Indexes
#
#  tr8n_m_oid_ot_k    (owner_id, owner_type, keyword) 
#
#++

class Tr8n::Emails::Asset < Tr8n::Media::Base

  def export_file_name
    name = path.split("/").last
    ext = name.split(".").last
    "#{keyword}.#{ext}"
  end

end
