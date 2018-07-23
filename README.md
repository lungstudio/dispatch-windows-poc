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

### To pick an order:
replace the order id in the request body  
``curl -X POST \
    http://localhost:3000/api/drivers/pick \
    -H 'Content-Type: application/json' \
    -d '{ "order_id": 2 }'``

### To delete all orders:
``curl -X DELETE \
    http://localhost:3000/api/orders/delete_all``

## Locust Load Test
1. install locust [here](https://docs.locust.io/en/stable/installation.html)
2. `pip install polling`
3. cd to `#{PROJECT_ROOT}/load_test/locust`
4. `locust -f locustfile.py UserLocust DriverLocust --host=http://localhost:3000`, change the host manually
5. go to `http://127.0.0.1:8089/` for locust dashboard
6. start test from dashboard

### load test configurations
`#{PROJECT_ROOT}/load_test/locust/locustfile.py`
Test special configs:  
- DRIVER_PICK_RATE:  
  the possibilty that a driver would pick this order, between 0 and 1
- DRIVER_POLL_INTERVAL:  
  how frequent a driver checks the order list

Locust configs: 
- `min_wait` & `max_wait`:  
    In addition to the task_set attribute, one usually wants to declare the min_wait and max_wait attributes. These are the minimum and maximum time respectively, in milliseconds, that a simulated user will wait between executing each task. min_wait and max_wait default to 1000, and therefore a locust will always wait 1 second between each task if min_wait and max_wait are not declared.

- `weight`:
    You can run two locusts from the same file like so:
    
    ``locust -f locust_file.py WebUserLocust MobileUserLocust``
    If you wish to make one of these locusts execute more often you can set a weight attribute on those classes. Say for example, web users are three times more likely than mobile users:
    
```
   class WebUserLocust(Locust):
        weight = 3
        ....
    
   class MobileUserLocust(Locust):
        weight = 1
        ....
```