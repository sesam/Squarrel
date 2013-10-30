require 'spec_helper'

describe Squarrel do
  describe "configuring" do
    describe "authentication callback" do
      it "invokes the correct block" do
        arg = nil

        Squarrel.configure do |config|
          config.user_authenticated do |user|
            arg = user
          end
        end

        Squarrel.send(:on_user_authenticated, "testing")
        expect(arg).to eq("testing")
      end
    end
  end
end
