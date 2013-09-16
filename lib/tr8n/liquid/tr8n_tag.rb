module Tr8n
  module Liquid
    class Tr8nTag < ::Liquid::Block
      def initialize(tag_name, markup, tokens)
         super
         @method = markup
      end

      def render(context)
        @method
      end
    end
  end
end

::Liquid::Template.register_tag('block', ::Tr8n::Liquid::Tr8nTag)
