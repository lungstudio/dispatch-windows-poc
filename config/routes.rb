Rails.application.routes.draw do

  resources :orders
  resources :drivers
  resources :users do
    member do
      post 'create_order'
    end
  end
end
