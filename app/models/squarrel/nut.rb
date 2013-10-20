require 'rbnacl'
require 'zlib'

module Squarrel
  # The 'nut' (SQRL nonce) that is created to authenticate a user.
  class Nut
    # Generates a new encrypted nut for a specific IP address.
    def self.generate(ip)
      payload = {
        ip: ip,
        ts: DateTime.now.to_i }

      message = JSON.generate(payload)

      enc = self.encrypt(message)

      "#{enc[:message].unpack("H*")[0]}.#{enc[:nonce].unpack("H*")[0]}"
    end

    private

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
