class Order < ApplicationRecord
  enum status: { pending: 'pending', picked: 'picked' }
end
