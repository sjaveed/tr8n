module Tr8n
  class Mailer < ActionMailer::Base

    def deliver(application, keyword, to_email, tokens = {}, options = {})
      email = application.email_templates.where(:keyword => keyword)
      raise "Email template does not exist" unless email

      from_email = options[:from_email] || "noreply@tr8nhub.com"

      attrs = {
          :email_id => email.id,
          :email_address => to_email,
          :data => tokens
      }
      attrs[:locale] = options[:locale]
      attrs[:from_user_id] = options[:from_user_id]
      attrs[:to_user_id] = options[:to_user_id]
      options[:delivery_log] = Tr8n::EmailLog.create(attrs)

      message = mail(:to => to_email, :from => from_email, :subject => email.render_subject(tokens, options)) do |format|
        format.text { render :text => email.render(:text, tokens, options) }
        format.html { render :text => email.render(:html, tokens, options) }
      end

      message.deliver
    end

  end
end
