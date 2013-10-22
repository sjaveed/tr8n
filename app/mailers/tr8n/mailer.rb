module Tr8n
  class Mailer < ActionMailer::Base

    def deliver(application, keyword, to_email, tokens = {}, options = {})
      email_template = application.email_templates.where(:keyword => keyword.to_s).first
      raise "Email template does not exist" unless email_template

      from_email = options[:from_email] || Tr8n::Config.noreply_email

      options[:email_log] = Tr8n::Emails::Log.create({
          :email_template       => email_template,
          :email                => to_email,
          :tokens               => tokens,
          :from                 => options[:from],
          :to                   => options[:to],
          :language             => options[:language] || Tr8n::RequestContext.current_language
      })

      options[:skip_decorations] = true

      message = mail(:to => to_email, :from => from_email, :subject => email_template.render_subject(tokens, options)) do |format|
        format.text { render :text => email_template.render_body(:text, tokens, options) }
        format.html { render :text => email_template.render_body(:html, tokens, options) }
      end

      message.deliver
    end

  end
end
