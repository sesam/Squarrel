require 'spec_helper'

describe Squarrel::User do
  let(:ip) { "127.0.0.1" }
  let(:nut) { Squarrel::Nut.generate(ip) }

  let(:key) { RbNaCl::SigningKey.generate }
  let(:pub_key) { Base64.urlsafe_encode64(key.verify_key.to_bytes).gsub("=", "") }
  let(:uri) { sqrl_uri(nut.to_s, 1, pub_key) }
  let(:sig) { Base64.urlsafe_encode64(key.sign(uri)).gsub("=", "") }

  let(:nut2) { Squarrel::Nut.validate(ip, uri, sig) }

  describe "authenticating" do
    context "with an invalid signature" do
      it "should fail" do
        altered = sig.to_s
        altered[0] = altered[0] == '0' ? '1' : '0'
        user = Squarrel::User.authenticate(ip, uri, altered)
        expect(user).to be_nil
      end
    end

    context "the first time" do
      it "should create a new user" do
        expect {
          user = Squarrel::User.authenticate(ip, uri, sig)
        }.to change{Squarrel::User.count}.by(1)
      end
    end

    context "subsequent times" do
      it "should return an existing user." do
        user = Squarrel::User.authenticate(ip, uri, sig)
        expect(user).not_to be_nil
        
        user = nil
        expect {
          user = Squarrel::User.authenticate(ip, uri, sig)
        }.not_to change{Squarrel::User.count}
        expect(user).not_to be_nil
      end
    end

    it "should return the created user" do
      user = Squarrel::User.authenticate(ip, uri, sig)

      expect(user).not_to be_nil
      expect(user).to be_a(Squarrel::User)
      expect(user.pub_key).to eq(nut2.sqrl_key)
    end

    it "should record the authentication" do
      user = Squarrel::User.authenticate(ip, uri, sig)
      expect(user.authentications.count).to eq(1)

      auth = user.authentications.first
      expect(auth.nut).to eq(nut2.to_s)
      expect(auth.orig_ip).to eq(ip)
      expect(auth.ip).to eq(ip)
    end
  end

  describe "completing authentication" do
    context "user has not previously authenticated" do
      it "should fail" do
        user = Squarrel::User.complete_authentication(ip, nut.to_s)
        expect(user).to be_nil
      end
    end

    context "wrong nut is used" do
      it "should fail" do
        user = Squarrel::User.authenticate(ip, uri, sig)
        expect(user).not_to be_nil

        altered = nut.to_s
        altered[0] = altered[0] == "0" ? "1" : "0"
        user = Squarrel::User.complete_authentication(ip, altered)
        expect(user).to be_nil
      end
    end

    context "user has previously authenticated" do
      before(:each) do
        Squarrel::User.authenticate(ip, uri, sig)
      end

      it "should return the user" do
        user = Squarrel::User.complete_authentication(ip, nut.to_s)
        expect(user).not_to be_nil
      end

      it "cannot use the same authentication twice" do
        user = Squarrel::User.complete_authentication(ip, nut.to_s)
        expect(user).not_to be_nil

        user = Squarrel::User.complete_authentication(ip, nut.to_s)
        expect(user).to be_nil
      end

      it "cannot complete authentication from a different endpoint" do
        user = Squarrel::User.complete_authentication("127.0.0.2", nut.to_s)
        expect(user).to be_nil
      end
    end
  end
end
