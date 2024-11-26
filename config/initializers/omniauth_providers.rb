Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer if Rails.env.development? || Rails.env.test?
  provider :google_oauth2, Rails.application.credentials.dig(:oauth, :google, :client_id), Rails.application.credentials.dig(:oauth, :google, :client_secret)
  provider :github, Rails.application.credentials.dig(:oauth, :github, :client_id), Rails.application.credentials.dig(:oauth, :github, :secret), scope: "user:email"
end
