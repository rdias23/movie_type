# Be sure to restart your server when you modify this file.

# Configure CSRF protection to work with our proxy setup
Rails.application.config.action_controller.forgery_protection_origin_check = false

# Allow requests from our proxy
Rails.application.config.hosts << "127.0.0.1.50703"
Rails.application.config.hosts << "127.0.0.1"
