require 'spec_helper'

describe "Authentication" do
  context "requesting a nut" do
    subject { page }

    sqrl_url_pattern = /^sqrl:\/\/.*?nut=(([0-9a-f]{100})\.([0-9a-f]{48}))$/i

    visit squarrel.login_path

    link = all("a[href^='sqrl://]")
    it "has a SQRL URI" do
      expect(link).not_to be_nil
    end
    it "only has one SQRL URI" do
      expect(link.length).to eq(0)
    end

    href = link["href"]
    it "has a valid nut" do
      expect(href).to match sqrl_url_pattern
    end

    context "authenticating" do
      context "with an invalid signature" do
        it "fails" do
          # TODO: Returns 403(?)
        end
      end

      context "with a valid signature" do
        it "succeeds" do
          # TODO: Returns 200
        end

        context "completing authentication" do
          context "from a different IP" do
            it "fails" do
              # TODO: Returns 403(?)
            end
          end

          context "from the original IP" do
            it "succeeds" do
              # TODO
            end

            it "invokes the user_authenticated callback" do
              # TODO
            end

            context "subsequen times" do
              it "fails" do
                # TODO
              end
            end
          end
        end
      end
    end
  end
end
