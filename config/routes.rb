# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    post 'drivers/pick' => 'drivers#pick'
    delete 'orders/delete_all' => 'orders#delete_all'
    resources :orders, only: %i[create index]
  end
end
