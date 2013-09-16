module Tr8n
  module Liquid
    class TrTag < ::Liquid::Block
      def initialize(tag_name, markup, tokens)
        super
        Tr8n::Logger.logger(:liquid).debug(tag_name)
        Tr8n::Logger.logger(:liquid).debug(markup)
        Tr8n::Logger.logger(:liquid).debug(tokens)
      end

      def render(context)
        label = super
        tokens = context.environments.first

        Tr8n::Logger.logger(:liquid).debug(label)
        Tr8n::Logger.logger(:liquid).debug(tokens)

        lang = Tr8n::Config.email_render_options[:language] || Tr8n::Config.default_language
        lang.translate(label, nil, tokens, Tr8n::Config.email_render_options[:options])
      end
    end
  end
end

::Liquid::Template.register_tag('tr', ::Tr8n::Liquid::TrTag)
