module Squarrel
  class Authentication < ActiveRecord::Base
    belongs_to :user
  end
end
