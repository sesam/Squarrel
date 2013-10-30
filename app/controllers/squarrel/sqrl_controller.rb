require_dependency "squarrel/application_controller"

module Squarrel
  class SqrlController < ApplicationController
    # Provides a URI or QR code, depending on the format.
    def code
    end

    # Renders a simple, unstyled login form.
    def form
    end
    
    # Callback for an authentication app.
    def callback
    end

    # Completes a previous authentication.
    def login
    end
  end
end
