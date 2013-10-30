require "squarrel/engine"

module Squarrel
  # Allows an application to configure the SQRL engine.
  def self.configure(&block)
    yield(@config)
  end

  private

  # Callback invoked when a user is authenticated.
  def self.on_user_authenticated(user)
    unless @config.on_user_authenticated.nil?
      @config.on_user_authenticated.call(user)
    end
  end

  # Provides controlled access to the SQRL configuration.
  class SquarrelConfig
    # Defines a callback to invoke when a user authenticates.
    def user_authenticated(&block)
      puts block
      on_user_authenticated = block
      puts on_user_authenticated
    end

    attr_accessor :on_user_authenticated
  end

  @config = SquarrelConfig.new
end
