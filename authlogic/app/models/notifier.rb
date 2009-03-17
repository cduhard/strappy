class Notifier < ActionMailer::Base
  default_url_options[:host] = SiteConfig.host_name
  
  def password_reset_instructions(user)
    subject       "Password Reset Instructions"
    from          "#{SiteConfig.app_name} Notifier <#{SiteConfig.email_from}>"
    recipients    user.email
    sent_on       Time.now
    body          :edit_password_reset_url => edit_password_reset_url(user.perishable_token)
  end
  
  def activation_instructions(user)
    subject "Activation Instructions"
    from          "#{SiteConfig.app_name} Notifier <#{SiteConfig.email_from}>"
    recipients user.email
    sent_on Time.now
    body :activation_url => register_url(user.perishable_token)
  end

  def activation_confirmation(user)
    subject "Activation Complete"
    from          "#{SiteConfig.app_name} Notifier <#{SiteConfig.email_from}>"
    recipients user.email
    sent_on Time.now
    body :root_url => root_url
  end
end