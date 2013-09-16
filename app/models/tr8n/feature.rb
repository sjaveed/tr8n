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
#-- Tr8n::ApplicationLanguage Schema Information
#
# Table name: tr8n_application_languages
#
#  id                INTEGER     not null, primary key
#  application_id    integer     not null
#  feature_id        integer     not null
#  created_at        datetime    not null
#  updated_at        datetime    not null
#
# Indexes
#
#  tr8n_app_lang_app_id    (application_id)
#
#++

class Tr8n::Feature < ActiveRecord::Base
  self.table_name = :tr8n_features

  attr_accessible :object, :keyword, :enabled

  belongs_to :object, :polymorphic => true

  def self.application_defaults
    {
        "javascript_sdk"      => {"enabled" => false, "description" => "JavaScript SDK",                  },
        "google_suggestions"  => {"enabled" => false, "description" => "Google Translation Suggestions",  },
        "shortcuts"           => {"enabled" => true,  "description" => "Keyboard Shortcuts",              },
        "decorations"         => {"enabled" => true,  "description" => "Custom Decorations",              },
        "glossary"            => {"enabled" => true,  "description" => "Application Glossary",            },
        "forum"               => {"enabled" => true,  "description" => "Translator Forum",                },
        "awards"              => {"enabled" => true,  "description" => "Awards",                          },
        "language_cases"      => {"enabled" => true,  "description" => "Language Cases",                  },
        "context_rules"       => {"enabled" => true,  "description" => "Context Rules",                   },
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

  def self.by_object(object)
    hash = defaults_for(object).clone

    feats = where("object_type = ? and object_id = ?", object.class.name, object.id).all
    feats.each do |feat|
      hash[feat.keyword]["enabled"] = feat.enabled?
    end

    hash
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
