require 'rails_helper'
require 'active_support/testing/time_helpers'
include ActiveSupport::Testing::TimeHelpers

RSpec.describe "Password", type: :request do
  fixtures :users
  let(:user) { users(:existing) }
  before(:all) do
    ActionMailer::Base.deliveries.clear
  end

  describe "GET /passwords/new" do
    it "returns http success" do
      get "/passwords/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /passwords" do
    it "creating a password reset sends an email and show instructions" do
      # TODO: need to decide whether to enqueue or perform jobs
      # for the moment, request spec will perform jobs, while model spec will enqueue jobs
      perform_enqueued_jobs do
        post passwords_path, params: { email_address: user.email_address }
      end
      # expect do
      #   post passwords_path, params: { email_address: user.email_address }
      # end.to have_enqueued_email(PasswordMailer, :reset).exactly(:once)

      expect(response).to redirect_to new_session_path
      follow_redirect!
      assert_select "div", text: "Password reset instructions sent (if user with that email address exists)."

      expect(ActionMailer::Base.deliveries.size).to eq(1)

      ActionMailer::Base.deliveries.first.tap do |mail|
        content = mail.html_part.body.to_s
        token = content.match(/passwords\/(.+)\/edit"/)[1]
        expect(User.find_by_password_reset_token!(token)).to eq(user)
      end
    end
  end

  describe "GET /passwords/:token/edit" do
    it "returns http success" do
      get edit_password_path(user.password_reset_token)
      expect(response).to have_http_status(:success)
      assert_select "form"
    end
  end

  describe "PUT /passwords/:token" do
    it "changes to users password with a valid token" do
      token = user.password_reset_token

      expect do
        patch password_path(token), params: { password: "W3lcome?" }
      end.not_to change { user.password_digest }
      expect(response).to redirect_to(edit_password_path(token))

      expect do
        patch password_path(token), params: { password: "W3lcome?", password_confirmation: "somethingelse" }
      end.not_to change { user.password_digest }
      expect(response).to redirect_to(edit_password_path(token))

      expect do
        patch password_path(token), params: { password: "short", password_confirmation: "short" }
      end.not_to change { user.password_digest }
      expect(response).to redirect_to(edit_password_path(token))

      expect do
        patch password_path(token), params: { password: "W3lcome?", password_confirmation: "W3lcome?" }
      end.to change { user.reload.password_digest }
      expect(response).to redirect_to(new_session_path)

      expect(User.authenticate_by(email_address: user.email_address, password: "W3lcome?")).to_not be_nil
    end
  end

  it "does not change a user's password with an expired token" do
    token = user.password_reset_token
    travel_to 16.minutes.from_now
    expect do
      patch password_path(token), params: { password: "W3lcome?", password_confirmation: "W3lcome?" }
    end.not_to change { user.password_digest }
    expect(response).to redirect_to(new_password_path)
  end
end
