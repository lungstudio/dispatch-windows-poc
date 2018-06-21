# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.integer :user_id
      t.integer :driver_id
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end
  end
end
