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
#-- Tr8n::Feature Schema Information
#
# Table name: tr8n_features
#
#  id             integer                        not null, primary key
#  object_type    character varying(255)         
#  object_id      integer                        
#  keyword        character varying(255)         
#  enabled        boolean                        
#  created_at     timestamp without time zone    not null
#  updated_at     timestamp without time zone    not null
#
# Indexes
#
#  tr8n_feats    (object_type, object_id) 
#
#++

class Tr8n::Feature < ActiveRecord::Base
  self.table_name = :tr8n_features

  attr_accessible :object, :keyword, :enabled

  belongs_to :object, :polymorphic => true

  def self.application_defaults
    {
        "inline_translations" => {"enabled" => true,  "container_only"=>false, "description" => "Allows translators to submit translations right on the site using a popup window.", },
        "google_suggestions"  => {"enabled" => false, "container_only"=>false, "description" => "Requests Google for translation suggestions",},
        "decorations"         => {"enabled" => true,  "container_only"=>false, "description" => "Allows developers to customize the styles of the inline decorations", },
        "shortcuts"           => {"enabled" => true,  "container_only"=>false, "description" => "Enables keyboard shortcuts for language switching and much more", },
        "context_rules"       => {"enabled" => true,  "container_only"=>false, "description" => "Enables language context rules for submitting translations based on the token values", },
        "language_cases"      => {"enabled" => true,  "container_only"=>false, "description" => "Enables language cases for modifying token values based on their place in a sentence", },
        "javascript_sdk"      => {"enabled" => false, "container_only"=>false, "description" => "Enables JavaScript SDK for translating text from within JavaScript",},
        "glossary"            => {"enabled" => true,  "container_only"=>false, "description" => "Application glossary",                       },
        "forum"               => {"enabled" => true,  "container_only"=>false, "description" => "Translator forums",                          },
        "awards"              => {"enabled" => true,  "container_only"=>false, "description" => "Translator awards",                          },
        "admin_translations"  => {"enabled" => true,  "container_only"=>true,  "description" => "Enables inline translations of the administration tools", },
        "open_registration"   => {"enabled" => true,  "container_only"=>true,  "description" => "Allow anyone to register as translator. If disabled, translators will be able to join by invitation only.",     },
        "language_flags"      => {"enabled" => true,  "container_only"=>false, "description" => "Displays flag icons next to languages in the language selector window and other sections of the site",   },
    }
  end

  def self.translator_defaults
    {
        "fallback_language"   => {"enabled" => false, "description" => "Fallback language"},
        "show_locked_keys"    => {"enabled" => false, "description" => "Show locked keys", :manager => true},
    }
  end

  def self.language_defaults
    {
        "fallback_language"   => {"enabled" => true, "description" => "Fallback language"},
    }
  end

  def self.defaults_for(object)
    return application_defaults if object.is_a?(Tr8n::Application)
    return translator_defaults if object.is_a?(Tr8n::Translator)
    return language_defaults if object.is_a?(Tr8n::Language)
    {}
  end

  def self.by_object(object, opts = {})
    hash = defaults_for(object).clone

    feats = where("object_type = ? and object_id = ?", object.class.name, object.id).all
    feats.each do |feat|
      hash[feat.keyword]["enabled"] = feat.enabled?
    end

    return hash unless opts[:slim]

    h = {}
    hash.each do |key, defs|
      h[key] = defs["enabled"]
    end
    h
  end

  def self.enabled?(object, keyword)
    by_object(object)[keyword.to_s]["enabled"]
  end

  def self.toggle(object, keyword, flag)
    feat = where("object_type = ? and object_id = ? and keyword = ?", object.class.name, object.id, keyword).first
    defs = defaults_for(object)[keyword]

    if defs["enabled"] == flag
      feat.destroy if feat
    else
      feat ? feat.update_attributes(:enabled => flag) : create(:object => object, :keyword => keyword, :enabled => flag)
    end

    flag
  end

end
