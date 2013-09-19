module Tr8n
  class Mailer < ActionMailer::Base

    def deliver(application, keyword, to_email, tokens = {}, options = {})
      email = application.email_templates.where(:keyword => keyword).first
      raise "Email template does not exist" unless email

      from_email = options[:from_email] || Tr8n::Config.noreply_email

      #attrs = {
      #    :email_id => email.id,
      #    :email_address => to_email,
      #    :data => tokens
      #}
      #attrs[:locale] = options[:locale]
      #attrs[:from_user_id] = options[:from_user_id]
      #attrs[:to_user_id] = options[:to_user_id]
      #options[:delivery_log] = Tr8n::EmailLog.create(attrs)

      options[:skip_decorations] = true

      message = mail(:to => to_email, :from => from_email, :subject => email.render_subject(tokens, options)) do |format|
        #format.text { render :text => email.render(:text, tokens, options) }
        format.html { render :text => email.render_body(:html, tokens, options) }
      end

      message.deliver
    end

  end
end
