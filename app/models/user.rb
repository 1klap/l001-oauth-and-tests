class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :omni_auth_identities, dependent: :destroy

  validates :email_address, presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            uniqueness: { case_sensitive: false }
  validates :password, on: [ :registration, :password_change ],
            presence: true,
            length: { minimum: 8, maximum: 72 }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def self.create_from_oauth(auth)
    email = auth.info.email
    user = self.new email_address: email, password: SecureRandom.base64(64).truncate_bytes(64)
    # assign_names_from_auth(auth, user)
    user.save
    user
  end

  def signed_in_with_oauth(auth)
    # User.assign_names_from_auth(auth, self)
    save if first_name_changed? || last_name_changed?
  end

  private

    # def self.assign_names_from_auth(auth, user)
    #   provider = auth["provider"]
    #   case provider
    #   when "developer"
    #     if user.first_name.blank? && user.last_name.blank?
    #       user.first_name = auth.info.name
    #       user.last_name = "Developer"
    #     end
    #   when "google_oauth2"
    #     if user.first_name.blank? && user.last_name.blank?
    #       user.first_name = auth.info.first_name
    #       user.last_name = auth.info.last_name
    #     end
    #   when "github"
    #     if user.first_name.blank? && user.last_name.blank?
    #       user.first_name = auth.info.first_name
    #       user.last_name = auth.info.last_name
    #     end
    #   end
    # end
end
