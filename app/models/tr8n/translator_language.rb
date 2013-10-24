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
#-- Tr8n::TranslatorLanguage Schema Information
#
# Table name: tr8n_translator_languages
#
#  id               integer                        not null, primary key
#  translator_id    integer                        
#  language_id      integer                        
#  primary          boolean                        
#  created_at       timestamp without time zone    not null
#  updated_at       timestamp without time zone    not null
#  position         integer                        
#
# Indexes
#
#  tr8n_trn_lang    (translator_id, language_id) 
#
#++

class Tr8n::TranslatorLanguage < ActiveRecord::Base
  self.table_name = :tr8n_translator_languages
  attr_accessible :translator, :language, :featured_index

  belongs_to :translator, :class_name => 'Tr8n::Translator'
  belongs_to :language, :class_name => 'Tr8n::Language'

  def self.find_or_create(translator, language)
    where("translator_id = ? and language_id = ?", translator.id, language.id).first || create(:translator => translator, :language => language)
  end

end
