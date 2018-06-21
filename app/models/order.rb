# frozen_string_literal: true

class Order < ApplicationRecord
  enum status: { pending: 'pending', picked: 'picked' }
end
