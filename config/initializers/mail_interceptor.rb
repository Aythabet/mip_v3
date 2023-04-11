options = { forward_emails_to: 'ayoub.benthabet@agence-inspire.com',
            deliver_emails_to: ["@agence-inspire.com"] }

unless (Rails.env.test? || Rails.env.production?)
  interceptor = MailInterceptor::Interceptor.new(options)
  ActionMailer::Base.register_interceptor(interceptor)
end
