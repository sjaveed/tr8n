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
#-- Tr8n::Country Schema Information
#
# Table name: tr8n_countries
#
#  id                integer                        not null, primary key
#  code              character varying(255)         
#  english_name      character varying(255)         
#  native_name       character varying(255)         
#  telephone_code    character varying(255)         
#  currency          character varying(255)         
#  created_at        timestamp without time zone    not null
#  updated_at        timestamp without time zone    not null
#
# Indexes
#
#  tr8n_countries_code    (code) 
#
#++

class Tr8n::Country < ActiveRecord::Base
  self.table_name = :tr8n_countries

  attr_accessible :code, :english_name, :native_name, :telephone_code, :currency

  has_many :country_languages, :class_name => ' Tr8n::CountryLanguage', :order => "position asc", :dependent => :destroy
  has_many :languages, :class_name => 'Tr8n::Language', :through => :country_languages, :order => "tr8n_country_languages.position asc"

  def self.by_code(code)
    where(:code => code).first
  end

end
