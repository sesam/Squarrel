require 'spec_helper'

describe Squarrel::SqrlController do
  SQRL_URI_PATTERN = /^sqrl:\/\/.*?nut=(([0-9a-f]{100})\.([0-9a-f]{48}))$/i

  context "requesting a nut" do
    it "should provide a SQRL URI" do
      get squarrel.code_path(format: :json)
      data = JSON.parse(response.body)
      
      expect(data["uri"]).not_to be_nil
      expect(data["uri"]).to match SQRL_URI_PATTERN
      expect(data["uri"]).to start_with squarrel.callback_url(protocol: :sqrl)
    end
  end

  context "authenticating" do
    let(:nut) { Squarrel::Nut.generate("127.0.0.1") }
    let(:key) { RbNaCl::SigningKey.generate }
    let(:pub_key) { Squarrel::Nut.base64_encode(key.verify_key.to_bytes) }
    let(:uri) do
      squarrel.callback_url(protocol: "sqrl",
                            nut: nut.to_s,
                            sqrlver: 1,
                            sqrlkey: pub_key)
    end

    context "with an invalid signature" do
      before do
        sig = Squarrel::Nut.base64_encode(key.sign(uri + "foo"))
        post uri, "sqrlsig=#{sig}"
      end

      it "fails" do
        expect(response.status).to eq(403)
      end
    end

    context "with a valid signature" do
      before do
        sig = Squarrel::Nut.base64_encode(key.sign(uri))

        # TODO: Need to figure out how to get the URL as the client sees it,
        # to verify the signature.
        ActionDispatch::Request.any_instance.stub(:original_url).and_return(uri)

        post uri, "sqrlsig=#{sig}"
      end

      it "succeeds" do
        expect(response.status).to eq(200)
      end
    end

    context "completing authentication" do
      # Creates and validates a nut.
      def authenticated_nut(ip)
        nut = Squarrel::Nut.generate(ip)
        key = RbNaCl::SigningKey.generate
        pub_key = Squarrel::Nut.base64_encode(key.verify_key.to_bytes)
        uri = sqrl_uri(nut.to_s, 1, pub_key)
        sig = Squarrel::Nut.base64_encode(key.sign(uri))
        user = Squarrel::User.authenticate(ip, uri, sig)

        raise "Failed to authenticate user" if user.nil?

        nut
      end
        
      context "from a different IP" do
        it "fails" do
          from_ip("127.0.0.2") do
            nut = authenticated_nut("127.0.0.1")
            post squarrel.login_path(nut: nut.to_s)
            expect(response.status).to eq(403)
          end
        end
      end

      context "from the original IP" do
        it "succeeds" do
          from_ip("127.0.0.1") do
            nut = authenticated_nut("127.0.0.1")
            post squarrel.login_path(nut: nut.to_s)
            expect(response.status).to eq(200)
          end
        end

        it "invokes the user_authenticated callback" do
          from_ip("127.0.0.1") do
            nut = authenticated_nut("127.0.0.1")
            user = nil
            Squarrel.configure do |config|
              config.user_authenticated do |u|
                user = u
              end
            end

            post squarrel.login_path(nut: nut.to_s)
            expect(user).not_to be_nil
          end
        end

        context "subsequent times" do
          it "fails" do
            from_ip("127.0.0.1") do
              nut = authenticated_nut("127.0.0.1")
              post squarrel.login_path(nut: nut.to_s)
              expect(response.status).to eq(200)

              post squarrel.login_path(nut: nut.to_s)
              expect(response.status).to eq(403)
            end
          end
        end
      end
    end
  end
end
