Squarrel::Engine.routes.draw do
  get "login", controller: "sqrl", action: "form", as: :login_form
  post "login", controller: "sqrl", action: "login", as: :login

  get "code", controller: "sqrl", action: "code", as: :code
  post "auth", controller: "sqrl", action: "callback", as: :callback
end
