# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  namespace :api do
    resources :users, only: [:create] do
      post 'create_order' => 'users#create_order'
    end

    resources :drivers, only: [] do
      post 'pick' => 'drivers#pick'
    end
  end

  delete 'utils/reset_all', to: 'utils#reset_all'

  resources :orders do
    member do
      patch 'reset'
    end
  end

  resources :users do
    member do
      post 'create_order'
    end
  end
end
