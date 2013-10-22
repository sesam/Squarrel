require 'spec_helper'

describe Squarrel::User do
  let(:ip) { "127.0.0.1" }
  let(:nut) { Squarrel::Nut.generate(ip) }

  let(:key) { RbNaCl::SigningKey.generate }
  let(:pub_key) { Base64.urlsafe_encode64(key.verify_key.to_bytes).gsub("=", "") }
  let(:uri) { sqrl_uri(nut.to_s, 1, pub_key) }
  let(:sig) { Base64.urlsafe_encode64(key.sign(uri)).gsub("=", "") }

  describe "authenticating" do
    before do
      Squarrel::Nut.stub(:verify).and_return(nut)
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

        expect {
          user = Squarrel::User.authenticate(ip, uri, sig)
        }.not_to change(Squarrel::User.count)

        expect(user).not_to be_nil
      end
    end

    it "should return the created user" do
      user = Squarrel::User.authenticate(ip, uri, sig)

      expect(user).not_to be_nil
      expect(user).to be_a(Squarrel::User)
      expect(user.pub_key).to eq(nut.sqrl_key)
    end

    it "should record the authentication" do
      user = Squarrel::User.authenticate(ip, uri, sig)
      expect(user.Authentications.count).to eq(1)

      auth = user.Authentications.first
      expect(auth.nut).to eq(nut.to_s)
      expect(auth.orig_ip).to eq(ip)
      expect(auth.ip).to eq(ip)
    end
  end
end
