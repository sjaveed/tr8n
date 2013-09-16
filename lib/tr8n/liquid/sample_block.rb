module Tr8n
  module Liquid
    class SampleBlock < ::Liquid::Block
      def initialize(tag_name, markup, tokens)
         super
         @rand = markup.to_i
      end

      def render(context)
        pp context
        super
      end
    end
  end
end

::Liquid::Template.register_tag('sample', ::Tr8n::Liquid::SampleBlock)