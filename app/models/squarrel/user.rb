module Squarrel
  class User < ActiveRecord::Base
    has_many :authentications

    # Verifies a user login and retrieves/creates the user.
    def self.authenticate(ip, uri, sig)
      nut = Nut.validate(ip, uri, sig)

      user = User.find_by(pub_key: nut.sqrl_key)
      user = User.create!(pub_key: nut.sqrl_key) if user.nil?

      # Record the authentication. All existing authentications are deleted.
      user.authentications.destroy_all
      user.authentications.create!(nut: nut.to_s,
                                   orig_ip: nut.ip,
                                   ip: nut.auth_ip)

      user
    rescue
      nil
    end

    # Completes the authentication handshake by checking for a recorded
    # authentication with the specified nut.
    #
    # ip: Authentication can only be completed by the endpoint that originally
    # requested the nut.
    # nut: The nut that was provided (as a string).
    def self.complete_authentication(ip, nut)
      auth = Authentication.find_by(nut: nut, orig_ip: ip)
      if auth.nil?
        nil
      else
        # The nut can only be used once.
        Authentication.where(nut: nut).destroy_all
        auth.user
      end
    end
  end
end
