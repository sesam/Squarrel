require_dependency "squarrel/application_controller"

module Squarrel
  class SqrlController < ApplicationController
    # Provides a URI or QR code, depending on the format.
    def code
      respond_to do |format|
        format.json { render json: get_sqrl_uri }
        format.xml  { render xml: get_sqrl_uri }
        # TODO: Image formats.
      end
    end

    # Renders a simple, unstyled login form.
    def form
      sqrl = get_sqrl_uri
      @nut = sqrl[:nut]
      @uri = sqrl[:uri]
    end
    
    # Callback for an authentication app.
    def callback
    end

    # Completes a previous authentication.
    def login
    end

    private

    # Generates a new SQRL nut and callback URI.
    def get_sqrl_uri
      nut = Nut.generate(request.remote_ip)
      uri = callback_url(protocol: "sqrl", nut: nut.to_s)

      { nut: nut,
        uri: uri }
    end
  end
end
