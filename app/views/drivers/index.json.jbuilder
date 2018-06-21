# frozen_string_literal: true

json.array! @drivers, partial: 'drivers/driver', as: :driver
