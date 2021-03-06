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
#-- Tr8n::CountryLanguage Schema Information
#
# Table name: tr8n_country_languages
#
#  id             integer                        not null, primary key
#  position       integer                        
#  country_id     integer                        
#  language_id    integer                        
#  official       boolean                        
#  primary        boolean                        
#  population     integer                        
#  created_at     timestamp without time zone    not null
#  updated_at     timestamp without time zone    not null
#
# Indexes
#
#  tr8n_cl_cid    (country_id) 
#  tr8n_cl_lid    (language_id) 
#
#++

class Tr8n::CountryLanguage < ActiveRecord::Base
  self.table_name = :tr8n_country_languages

  attr_accessible :country, :language, :primary, :official, :position

  belongs_to :country, :class_name => 'Tr8n::Country'
  belongs_to :language, :class_name => 'Tr8n::Language'

  def self.find_or_create(country, language)
    where("country_id = ? and language_id = ?", country.id, language.id).first || create(:country => country, :language => language)
  end

end
