from locust import HttpLocust, TaskSet, task
from threading import Thread
import json
import polling
import random
import resource
import requests
import time

# GLOBAL VARIABLES
HOST = 'https://gogovan-load-test.herokuapp.com'
DRIVER_POLL_INTERVAL = 0.5  # how frequent a driver checks the order list
ORDERS = []

# run before test
print('------- Running setup -------')
resource.setrlimit(resource.RLIMIT_NOFILE, (10240, 9223372036854775807))
requests.post(HOST + '/api/utils/flush_redis')

# thread to remove the order id after
def thread_remove_order_id(order_id):
    time.sleep(3)
    ORDERS.remove(order_id)

class UserCreateOrderBehaviour(TaskSet):
    @task
    def create_order(self):
        # create order, then append order id to ORDERS list
        res = self.client.post('/api/orders')
        content = res.content
        if content:
            order_id = json.loads(res.content)['order']['id']
            ORDERS.append(order_id)
            t = Thread(target = thread_remove_order_id, args = (order_id, ))
            t.start()

class DriverPickOrderBehaviour(TaskSet):
    @task
    def wait_and_pick_order(self):
        # poll ORDERS list for any new pending orders
        self.poll_order()

        if ORDERS:
            # order found! randomly pick one, and introduce a random delay within 3sec before picking
            order_id = random.choice(ORDERS)

            # pick the order
            with self.client.post('/api/drivers/pick', { 'order_id' : order_id }, catch_response=True) as res:
                if res.status_code == 200:
                    # winner
                    print('Winner order: ' + res.content)
                    print('Current size of ORDERS: ' + str(len(ORDERS)))
                elif res.status_code == 403:
                    # mark 403 as success
                    res.failure(json.loads(res.content)['error_key'])

    def poll_order(self):
        polling.poll(
            lambda: ORDERS,
            step=DRIVER_POLL_INTERVAL,
            check_success=self.is_orders_exist,
            poll_forever=True
        )

    def is_orders_exist(self, response):
        # returns true if list is not empty
        return ORDERS

class UserLocust(HttpLocust):
    host = HOST
    task_set = UserCreateOrderBehaviour
    min_wait = 5000
    max_wait = 6000
    weight = 1
    stop_timeout = 300

class DriverLocust(HttpLocust):
    host = HOST
    task_set = DriverPickOrderBehaviour
    min_wait = 100
    max_wait = 1000
    weight = 20
    stop_timeout = 300
