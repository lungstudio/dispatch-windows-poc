# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  delete 'utils/reset_all', to: 'utils#reset_all'

  resources :orders do
    member do
      patch 'reset'
      patch 'start_lottery'
    end
  end

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
