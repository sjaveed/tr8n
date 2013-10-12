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

module Tr8n
  module Liquid
    class AssetTag < ::Liquid::Tag
      def initialize(tag_name, markup, tokens)
        super
        @options = markup.scan(/[\w.]*\s|[\w]*=".*?"|[\w]*='.*?'/).collect{|o| o.strip}
        @key = @options.size > 0 ? @options.shift : markup.strip
      end

      def render(context)
        asset = Tr8n::RequestContext.current_application.email_assets.where(:keyword => @key).first
        return "[Error: Asset '#{@key}' does not exist in this application]" unless asset

        opts = Tr8n::RequestContext.email_render_options

        if opts[:mode].to_s == 'text' or @options.include?('url')
          return asset.url(:original, :full => true)
        end

        "<img src='#{asset.url(:original, :full => true)}' #{@options.join(" ")}>"
      end
    end
  end
end

::Liquid::Template.register_tag('asset', ::Tr8n::Liquid::AssetTag)
