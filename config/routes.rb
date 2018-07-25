# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    post 'drivers/pick' => 'drivers#pick'
    post 'utils/flush_redis' => 'utils#flush_redis'
    resources :orders, only: %i[create]
  end
end
