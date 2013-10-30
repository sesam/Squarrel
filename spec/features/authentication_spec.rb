require 'spec_helper'

describe "Login form" do
  context "requesting a nut" do
    sqrl_url_pattern = /^sqrl:\/\/.*?nut=(([0-9a-f]{100})\.([0-9a-f]{48}))$/i

    before(:each) do
      visit squarrel.login_form_path
    end

    subject { page }

    it "has a SQRL URI" do
      link = all("a[href^='sqrl://']")
      expect(link).not_to be_nil
    end
    it "only has one SQRL URI" do
      link = all("a[href^='sqrl://']")
      expect(link.length).to eq(1)
    end

    it "has a valid nut" do
      link = all("a[href^='sqrl://']").first
      href = link["href"]
      expect(href).to match sqrl_url_pattern
    end
  end
end
