# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  resources :orders
  resources :drivers do
    member do
      post 'pick'
    end
  end
  resources :users do
    member do
      post 'create_order'
    end
  end
end
