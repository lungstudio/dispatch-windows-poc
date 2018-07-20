# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    resources :orders, only: %i[create index]

    post 'drivers/pick' => 'drivers#pick'
  end
end
