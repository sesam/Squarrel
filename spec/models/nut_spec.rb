require 'spec_helper'

describe Squarrel::Nut do
  describe "generating a nut" do
    it "should return a message/nonce pair" do
      expect(Squarrel::Nut.generate("127.0.0.1").to_s)
      .to match(/[0-9a-z]{32,}\.[0-9a-z]{32,}/i)
    end

    it "should return a different nonce every time" do
      nuts = []
      10.times.each do
        nuts << Squarrel::Nut.generate("127.0.0.1")
      end

      expect(nuts.length).to eq(10)

      nonces = nuts.map { |n| n.to_s.split(".")[0] }
      expect(nonces.length).to eq(10)
      expect(nonces.uniq.length).to eq(10)
    end
  end

  describe "validating a nut" do
    # The fake user's IP address
    let(:ip) { "127.0.0.1" }

    # New nut generated for the user upon request.
    let!(:nut) { Squarrel::Nut.generate(ip).to_s }

    # Generate a pub/sec keypair for the fake user.
    let(:key) { RbNaCl::SigningKey.generate }
    let(:pub_key) { Base64.urlsafe_encode64(key.verify_key.to_bytes).gsub("=", "") }

    let(:orig_uri) { sqrl_uri(nut) }
    
    # The URI that is signed by the user and POSTed to.
    let(:post_uri) { sqrl_uri(nut, 1, pub_key) }

    # The POST URI, signed by the user's private key.
    def sign(uri)
      Base64.urlsafe_encode64(key.sign(uri)).gsub("=", "")
    end

    context "with a corrupted signature" do
      it "should complain about the signature" do
        uri = sqrl_uri(nut, 1, pub_key)
        sig = sign(uri)
        sig[0] = '&'
        expect {
          Squarrel::Nut.validate(ip, uri, sig)
        }.to raise_error Squarrel::BadNut, "Invalid signature."
      end
    end

    context "with a corrupted URI" do
      it "should comlain about the URI" do
        bad_uri = "sqrl::GAeq4t.4qq.com"
        expect {
          Squarrel::Nut.validate(ip, bad_uri, sign(bad_uri))
        }.to raise_error Squarrel::BadNut, "Invalid URI."
      end
    end

    context "with an altered nonce" do
      it "should complain about the nonce" do
        split = nut.split(".")
        nonce = split[1]
        nonce[0] = nonce[0] == "0" ? "1" : "0"
        altered = split.join(".")

        uri = sqrl_uri(altered, 1, pub_key)
        expect {
          Squarrel::Nut.validate(ip, uri, sign(uri))
        }.to raise_error Squarrel::BadNut, /nonce/
      end
    end

    context "with an altered nut" do
      it "should complain about the nonce" do
        split = nut.split(".")
        val = split[0]
        val[0] = val[0] == "0" ? "1" : "0"
        altered = split.join(".")

        uri = sqrl_uri(altered, 1, pub_key)
        expect {
          Squarrel::Nut.validate(ip, uri, sign(uri))
        }.to raise_error Squarrel::BadNut, /nonce/
      end
    end

    context "that has expired" do
      it "complains about the expired nut" do
        Timecop.freeze(DateTime.now + 10.minutes) do
          expect {
            Squarrel::Nut.validate(ip, post_uri, sign(post_uri))
          }.to raise_error Squarrel::BadNut, /expired/
        end
      end
    end

    context "with a mismatching IP" do
      context "and 'enforce' option" do
        it "complains about the mismatched IP" do
          uri = post_uri + "&sqrlopt=enforce"
          expect {
            Squarrel::Nut.validate(
              "127.0.0.2",
              uri,
              sign(uri))
          }.to raise_error Squarrel::BadNut, /ip/i
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

    context "with a bad signature" do
      it "should complain about the signature" do
        expect {
          Squarrel::Nut.validate(ip, post_uri, sign(post_uri+"#"))
        }.to raise_error Squarrel::BadNut, /signature/
      end
    end

    context "with a valid signature" do
      it "should decrypt and validate successfully" do
        result = Squarrel::Nut.validate(ip, post_uri, sign(post_uri))

        expect(result).not_to be_nil
        expect(result).to be_a Squarrel::Nut
        expect(result.to_s).to eq(nut)

        expect(result.ip).to eq(ip)
        expect(result.timestamp).not_to be_nil
        expect(result.timestamp).to be <= Time.now.to_i
        expect(result.nut.unpack("H*")[0]).to eq(nut.split(".")[0])
        expect(result.nonce.unpack("H*")[0]).to eq(nut.split(".")[1])
        expect(result.auth_ip).to eq(ip)
        expect(result.auth_time).not_to be_nil
        expect(result.auth_time).to be <= Time.now.to_i
        expect(result.sqrl_key).not_to be_nil
        expect(result.sqrl_key).to eq(pub_key)
      end
    end
  end
end

