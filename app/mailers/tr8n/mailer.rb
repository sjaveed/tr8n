module Tr8n
  class Mailer < ActionMailer::Base

    def deliver_offline(options = {})
      log = Tr8n::Emails::Log.find_by_id(options[:log_id])
      return unless log

      from_email = options[:from_email] || Tr8n::Config.noreply_email
      email_template = log.email_template
      tokens = log.tokens

      options[:email_log] = log

      tokens = tokens.merge({
        "email_log" => {
          "key" => log.key,
          "href" => log.link_url
        }
      })

      options[:skip_decorations] = true

      message = mail(:to => log.email, :from => from_email, :subject => email_template.render_subject(tokens, options)) do |format|
        format.text { render :text => email_template.render_body(:text, tokens, options) }
        format.html { render :text => email_template.render_body(:html, tokens, options) }
      end

      log.sent_at = Time.now
      log.save

      message.deliver
    end

    def deliver(application, keyword, to_email, tokens = {}, options = {})
      email_template = application.email_templates.where(:keyword => keyword.to_s).first
      raise "Email template does not exist" unless email_template

      log = Tr8n::Emails::Log.create({
           :email_template       => email_template,
           :email                => to_email,
           :tokens               => tokens,
           :from                 => options[:from],
           :to                   => options[:to],
           :language             => options[:language] || Tr8n::RequestContext.current_language
       })

      Tr8n::OfflineTask.schedule(self.class.name, :deliver_offline, options.merge({
        :log_id => log.id
      }))
    end

  end
end
