require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  fixtures :users
  let(:user) { users(:existing) }

  describe "GET /session/new" do
    it "returns http success" do
      get "/session/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /session" do
    it "sign a user in when credentials are valid" do
      user.sessions.destroy_all
      expect do
        post session_path, params: { email_address: user.email_address, password: "password" }
      end.to change { user.sessions.count }.from(0).to(1)
    end

    it "does not sign a user in when credentials are invalid" do
      user.sessions.destroy_all
      expect do
        post session_path, params: { email_address: user.email_address, password: "wrong-password" }
      end.not_to change { user.sessions.count }
    end
  end

  describe "DELETE /session" do
    it "sign a user out" do
      post session_path, params: { email_address: user.email_address, password: "password" }
      expect(response).to redirect_to root_path
      expect(user.reload.sessions.count).to eq(1)
      follow_redirect!

      expect do
        delete session_path
      end.to change { user.sessions.count }.from(1).to(0)
      expect(response).to redirect_to new_session_path
    end
  end
end
