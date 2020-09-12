Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get "/", to: "home#home"
  post "/create", to: "home#create"
  get "/ready" , to: "home#ready"
  get "/download", to: "home#download"
end
