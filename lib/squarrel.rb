require "squarrel/engine"

module Squarrel
  # Allows an application to configure the SQRL engine.
  def self.configure(&block)
    block.call(self.config ||= SquarrelConfig.new)
  end

  class << self
    attr_accessor :config
  end

  private

  # Provides controlled access to the SQRL configuration.
  class SquarrelConfig
    # Defines a callback to invoke when a user authenticates.
    def user_authenticated(&block)
      @on_user_authenticated = block
    end

    # The callback to be invoked when a user authenticates.
    def on_user_authenticated(user)
      @on_user_authenticated.call(user) unless @on_user_authenticated.nil?
    end
  end
end
