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
    class TrTag < ::Liquid::Block
      def initialize(tag_name, markup, tokens)
        super
        #Tr8n::Logger.logger(:liquid).debug(tag_name)
        #Tr8n::Logger.logger(:liquid).debug(markup)
        #Tr8n::Logger.logger(:liquid).debug(tokens)
      end

      def render(context)
        label = super
        tokens = context.environments.first

        #Tr8n::Logger.logger(:liquid).debug(label)


        lang = Tr8n::RequestContext.email_render_options[:language] || Tr8n::Config.default_language

        #Tr8n::Logger.logger(:liquid).debug(lang.locale)

        lang.translate(label, nil, tokens, Tr8n::RequestContext.email_render_options[:options])
      end
    end
  end
end

::Liquid::Template.register_tag('tr', ::Tr8n::Liquid::TrTag)
