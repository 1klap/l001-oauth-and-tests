require 'rails_helper'

RSpec.describe User, type: :model do
  fixtures :users
  let(:existing_user) { users :existing }
  let(:existing_user_without_password) { users :existing_no_pass }

  it "requires a valid email" do
    user = User.new(email_address: "", password: "password")
    expect(user).to_not be_valid
    user.email_address = nil
    expect(user).to_not be_valid
    user.email_address = "invalid"
    expect(user).to_not be_valid
    user.email_address = "johndoe@example.com"
    expect(user).to be_valid
  end

  it "requires a unique email" do
    expect(existing_user.persisted?).to be_truthy
    user = User.new(email_address: "existing@example.com", password: "password")
    expect(user).to be_invalid
  end

  context "on registration" do
    it "requires a valid password" do
      user = User.new(email_address: "johndoe@example.com")
      expect(user.valid?(:registration)).to be_falsey
      user.password = 'a' * 7
      expect(user.valid?(:registration)).to be_falsey
      user.password = 'é' * 72 # Too long in bytesize for bcrypt
      expect(user.valid?(:registration)).to be_falsey
      user.password = 'a' * 73
      expect(user.valid?(:registration)).to be_falsey
      user.password = 'a' * 72
      expect(user.valid?(:registration)).to be_truthy
    end
  end

  context "on authentication" do
    it "only accepts the right password" do
      expect(User.authenticate_by(email_address: "existing@example.com", password: nil)).to be_falsey
      expect(User.authenticate_by(email_address: "existing@example.com", password: "")).to be_falsey
      expect(User.authenticate_by(email_address: "existing@example.com", password: "wrong")).to be_falsey
      expect(User.authenticate_by(email_address: "existing@example.com", password: "password")).to_not be_nil
      expect(User.authenticate_by(email_address: "existing_no_pass@example.com", password: "password")).to be_falsey
      expect(User.authenticate_by(email_address: "existing_no_pass@example.com", password: "")).to be_falsey
      expect(User.authenticate_by(email_address: "existing_no_pass@example.com", password: nil)).to be_falsey
      expect do
        User.authenticate_by(email_address: "existing_no_pass@example.com")
      end.to raise_exception(ArgumentError)
    end
  end
end
