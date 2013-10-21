require 'rbnacl'
require 'zlib'

module Squarrel
  # The 'nut' (SQRL nonce) that is created to authenticate a user.
  class Nut
    # Nuts expire 5 minutes after they are created.
    EXPIRATION_SECONDS = 300

    #  Constructs a new nut for a specific user/IP.
    def self.generate(ip)
      timestamp = Time.now.to_i
      
      payload = {
        "ip" => ip,
        "ts" => timestamp }

      message = JSON.generate(payload)
      enc = self.encrypt(message)

      nut = enc[:message]
      nonce = enc[:nonce]

      new(ip, timestamp, nut, nonce)
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
        nut = [split[0]].pack("H*")
        nonce = [split[1]].pack("H*")

        message = decrypt(nut, nonce)
        message = JSON.parse(message)
      rescue
        raise Squarrel::BadNut.new("Received an invalid nonce.")
      end

      # Check the nut timestamp.
      auth_time = Time.now.to_i
      timestamp = message["ts"].to_i
      delta = auth_time - timestamp
      raise Squarrel::BadNut.new("Nonce has expired.") if delta > EXPIRATION_SECONDS

      # If "enforce" was specified, check the IP.
      orig_ip = message["ip"]
      if sqrl_options.include? "enforce"
        raise Squarrel::BadNut.new("IP address mismatch.") if ip != orig_ip
      end
      
      new(orig_ip, timestamp, nut, nonce, ip, auth_time, sqrlkey)
    end

    attr_reader :auth_ip, :sqrl_key, :ip, :nut, :nonce, :timestamp, :auth_time

    private_class_method :new

    def initialize(ip, timestamp, nut, nonce, auth_ip = nil, auth_time = nil, sqrl_key = nil)
      @ip = ip
      @timestamp = timestamp
      @nut = nut
      @nonce = nonce
      @auth_ip = auth_ip
      @auth_time = auth_time
      @sqrl_key = sqrl_key
    end

    def to_s
      "#{nut.unpack("H*")[0]}.#{nonce.unpack("H*")[0]}"
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
