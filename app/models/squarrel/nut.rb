require 'rbnacl'
require 'zlib'

module Squarrel
  # The 'nut' (SQRL nonce) that is created to authenticate a user.
  class Nut
    # Nuts expire 5 minutes after they are created.
    EXPIRATION_SECONDS = 300

    # Generates a new encrypted nut for a specific IP address.
    def self.generate(ip)
      payload = {
        "ip" => ip,
        "ts" => Time.now.to_i }

      message = JSON.generate(payload)

      enc = self.encrypt(message)

      "#{enc[:message].unpack("h*")[0]}.#{enc[:nonce].unpack("h*")[0]}"
    end

    # Validates a nut and signature provided by the user.
    def self.validate(ip, uri, sig)
      begin
        sig = base64_decode(sig)
      rescue
        raise Squarrel::BadNut.new("Invalid signature.")
      end

      begin
        query = CGI::parse(URI.parse(uri).query)
        nut = query["nut"].first
        sqrlkey = query["sqrlkey"].first
        sqrlopt = query["sqrlopt"].first
        sqrlver = query["sqrlver"].first
      rescue
        raise Squarrel::BadNut.new("Invalid URI.")
      end

      raise Squarrel::BadNut.new("Missing nut parameter.") if nut.nil?
      raise Squarrel::BadNut.new("Missing sqrlkey parameter.") if sqrlkey.nil?
      raise Squarrel::BadNut.new("Missing sqrlver parameter.") if sqrlver.nil?
      raise Squarrel::BadNut.new("Unsupported SQRL version: #{sqrlver}") if sqrlver != "1"

      sqrl_options = []
      sqrl_options = sqrlopt.split(",") unless sqrlopt.nil?

      # Extract the pub key from the URI.

      # Validate the signature.
      begin
        pub_key = RbNaCl::VerifyKey.new(base64_decode(sqrlkey))
        pub_key.verify!(uri, sig)
      rescue
        raise Squarrel::BadNut.new("Failed to validate signature.")
      end

      begin
        # Decrypt the provided nut.
        split = nut.split(".")
        nut = [split[0]].pack("h*")
        nonce = [split[1]].pack("h*")

        nut = decrypt(nut, nonce)
        nut = JSON.parse(nut)
      rescue
        raise Squarrel::BadNut.new("Received an invalid nonce.")
      end

      # Check the nut timestamp.
      delta = Time.now.to_i - nut["ts"].to_i
      raise Squarrel::BadNut.new("Nonce has expired.") if delta > EXPIRATION_SECONDS

      # If "enforce" was specified, check the IP.
      if sqrl_options.include? "enforce"
        orig_ip = nut["ip"]
        raise Squarrel::BadNut.new("IP address mismatch.") if ip != orig_ip
      end
      
      # Record and return the successful authentication.
      Authentication.authenticate(ip, orig_ip, nut, sqrlkey)
    end

    private

    # Base64-encode some data, trimming trailing "=".
    def self.base64_encode(data)
      Base64.urlsafe_encode64(data).gsub("=", "")
    end

    # Decode some Base64-encoded data.
    def self.base64_decode(input)
      # Add trailing "=", if required.
      input = input + ("=" * (4 - (input.length % 4))) if input.length % 4 != 0
      Base64.urlsafe_decode64(input)
    end

    # Decrypts a message with a known nonce.
    def self.decrypt(message, nonce)
      box = RbNaCl::SecretBox.new(key)
      box.decrypt(nonce, message)
    end

    # Encrypts a message with a newly generated nonce.
    def self.encrypt(message)
      box = RbNaCl::SecretBox.new(key)
      nonce = RbNaCl::Random.random_bytes(box.nonce_bytes)

      { message: box.encrypt(nonce, message),
        nonce: nonce }
    end

    # Creates a symmetric key that will be used to encrypt the nut.
    def self.key
      @key ||= RbNaCl::Random.random_bytes(RbNaCl::SecretBox.key_bytes)
    end
  end
end
