Rails.application.routes.draw do
  mount Squarrel::Engine => "/sqrl"
end
