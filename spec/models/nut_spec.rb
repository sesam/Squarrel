require 'spec_helper'

describe Squarrel::Nut do
  describe "Generating a nut" do
    it "should return a message/nonce pair" do
      expect(Squarrel::Nut.generate("127.0.0.1")).to match(/[0-9a-z]{32,}\.[0-9a-z]{32,}/i)
    end

    it "should return a different nonce every time" do
      nuts = []
      10.times.each do
        nuts << Squarrel::Nut.generate("127.0.0.1")
      end

      expect(nuts.length).to eq(10)

      nonces = nuts.map { |n| n.split(".")[0] }
      expect(nonces.length).to eq(10)
      expect(nonces.uniq.length).to eq(10)
    end
  end
end

