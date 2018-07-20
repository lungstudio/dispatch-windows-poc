# README

### To run the POC:

1. `rails db:reset db:migrate`
2. `redis-server`
3. `bundle exec rake dispatch_window_channels_monitor:run`
4. `rails s`

### To create order:
``curl -X POST \
    http://localhost:3000/api/orders``
    
### To list pending orders:
``curl -X GET \
    http://localhost:3000/api/orders``

### To pick and order:
replace the order id in the request body  
``curl -X POST \
    http://localhost:3000/api/drivers/pick \
    -H 'Content-Type: application/json' \
    -d '{ "order_id": 2 }'``
