from locust import HttpLocust, TaskSet, task
import json
import polling
import random
import time

DRIVER_PICK_RATE = 1.0      # the possibilty that a driver would pick this order, between 0 and 1
DRIVER_POLL_INTERVAL = 1    # how frequent a driver checks the order list
ORDERS = []

class UserCreateOrderBehaviour(TaskSet):
    @task
    def create_order(self):
        # create order, then append order id to ORDERS list
        res = self.client.post('/api/orders')
        ORDERS.append(json.loads(res.content)['order']['id'])

class DriverPickOrderBehaviour(TaskSet):
    @task
    def wait_and_pick_order(self):
        # poll ORDERS list for any new pending orders
        self.poll_order()

        if ORDERS and random.random() < DRIVER_PICK_RATE:
            # order found! randomly pick one, and introduce a random delay within 3sec before picking
            order_id = random.choice(ORDERS)
            time.sleep(random.random() * 3)

            # pick the order
            with self.client.post('/api/drivers/pick', { 'order_id' : order_id }, catch_response=True) as res:
                if res.ok:
                    # winner
                    print('Winner order: ' + res.content)
                    ORDERS.remove(order_id)
                elif res.status_code == 403:
                    # mark 403 as success
                    res.success()

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
    task_set = UserCreateOrderBehaviour
    min_wait = 5000
    max_wait = 10000
    weight = 1

class DriverLocust(HttpLocust):
    task_set = DriverPickOrderBehaviour
    weight = 100
