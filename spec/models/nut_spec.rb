require 'spec_helper'

describe Squarrel::Nut do
  describe "generating a nut" do
    it "should return a message/nonce pair" do
      expect(Squarrel::Nut.generate("127.0.0.1")).to match(/[0-9a-z]{32,}\.[0-9a-z]{32,}/i)
    end

    it "should return a different nonce every time" do
      nuts = []
      10.times.each do
        nuts << Squarrel::Nut.generate("127.0.0.1")
      end

      expect(nuts.length).to eq(10)

      nonces = nuts.map { |n| n.split(".")[0] }
      expect(nonces.length).to eq(10)
      expect(nonces.uniq.length).to eq(10)
    end
  end

  describe "validating a nut" do
    # The fake user's IP address
    let(:ip) { "127.0.0.1" }

    # New nut generated for the user upon request.
    let(:nut) { Squarrel::Nut.generate(ip) }

    # Generate a pub/sec keypair for the fake user.
    let(:key) { RbNaCl::SigningKey.generate }
    let(:pub_key) { Base64.urlsafe_encode64(key.verify_key.to_bytes).gsub("=", "") }

    # Pretend this was the callback URL handed to the user.
    let(:orig_uri) { "sqrl://example.com/sqrl/login?nut=#{nut}" }
    
    # The URI that is signed by the user and POSTed to.
    let(:post_uri) { orig_uri + "&sqrlver=1&sqrlkey=#{pub_key}" }
    
    # The POST URI, signed by the user's private key.
    def sign(uri)
      Base64.urlsafe_encode64(key.sign(uri)).gsub("=", " ")
    end

    context "that has expired" do
      Timecop.freeze(DateTime.now + 10.minutes) do
        it "complains about the expired nut" do
          expect {
            Squarrel::Nut.validate(ip, post_uri, sign(post_uri))
          }.to raise_error Squarrel::BadNut, /expired/
        end
      end
    end

    context "with a mismatching IP" do
      context "and 'enforce' option" do
        it "complains about the mismatched IP" do
          expect {
            Squarrel::Nut.validate(
              "127.0.0.2",
              post_uri + "&sqrlopt=enforce",
              sign(post_uri))
          }.to raise_error Squarrel::BadNut, /ip/
        end
      end

      context "but no 'enforce' option" do
        it "ignores the mismatched IP" do
          expect {
            Squarrel::Nut.validate(
              "127.0.0.2",
              post_uri, sign(post_uri))
          }.not_to raise_error
        end
      end
    end

    context "with a valid signature" do
      it "should decrypt and validate successfully" do
        result = Squarrel::Nut.validate(post_uri, sign(post_uri))

        expect(result).not_to be_nil
        expect(result).to be_a Squarrel::Authentication
      end
    end
  end
end

