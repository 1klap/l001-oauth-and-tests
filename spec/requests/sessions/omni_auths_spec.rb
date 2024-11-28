require 'rails_helper'

RSpec.describe "Sessions:OmniAuths", type: :request do
  fixtures :users, :omni_auth_identities
  let(:existing) { users(:existing) }
  let(:existing_no_identity) { users(:existing_no_pass) }

  describe "GET /auth/:provider/callback" do
    context "existing user with omni_auth_identity" do
      it "creates no user and signs in" do
        mock_omniauth_provider("github", email: existing.email_address, uid: existing.omni_auth_identities.first.uid)
        existing.sessions.destroy_all

        expect do
          get "/auth/github/callback"
        end.to change { User.count }.by(0)
                                    .and change { OmniAuthIdentity.count }.by(0)
        expect(existing.sessions.count).to eq 1
        expect(response).to redirect_to root_path
        follow_redirect!
        expect(response.body).to include "Current.user&.email_address = #{existing.email_address}"
      end
    end

    context "existing user without omni_auth_identity" do
      it "creates no user and signs in" do
        mock_omniauth_provider("github", email: existing_no_identity.email_address, uid: 45678)
        existing_no_identity.sessions.destroy_all

        expect do
          get "/auth/github/callback"
        end.to change { User.count }.by(0)
                                    .and change { OmniAuthIdentity.count }.by(1)
        expect(existing_no_identity.omni_auth_identities.first).to have_attributes uid: "45678", provider: "github"
        expect(existing_no_identity.sessions.count).to eq 1
        expect(response).to redirect_to root_path
        follow_redirect!
        expect(response.body).to include "Current.user&.email_address = #{existing_no_identity.email_address}"
      end
    end

    context "new user" do
      it "creates a new user and signs in" do
        mock_omniauth_provider("github", email: "new@example.com", uid: 98765)

        expect do
          get "/auth/github/callback"
        end.to change { User.count }.by(1)
                                    .and change { OmniAuthIdentity.count }.by(1)
        new_user = User.order(created_at: :desc).take
        expect(new_user.omni_auth_identities.first).to have_attributes uid: "98765", provider: "github"
        expect(new_user.sessions.count).to eq 1
        expect(response).to redirect_to root_path
        follow_redirect!
        expect(response.body).to include "Current.user&.email_address = new@example.com"
      end
    end
  end

  def mock_omniauth_provider(provider, email:, uid:)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[provider.to_sym] = OmniAuth::AuthHash.new({
                                                                          provider: provider,
                                                                          uid: uid,
                                                                          info: {
                                                                            email: email
                                                                          }
                                                                        })
  end
end
