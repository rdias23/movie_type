Rails.application.configure do
  config.action_mailer.delivery_method = Rails.env.development? ? :letter_opener : :smtp
  
  if Rails.env.production?
    config.action_mailer.smtp_settings = {
      address: ENV['SMTP_ADDRESS'],
      port: ENV['SMTP_PORT'],
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD'],
      authentication: :plain,
      enable_starttls_auto: true
    }
  end
  
  config.action_mailer.default_url_options = {
    host: ENV.fetch('APP_HOST', 'localhost'),
    port: ENV.fetch('PORT', 3000)
  }
end
