import random
import time

def mock():
    unix_time = int(time.time())
    rssi = -60

    time_signal = []

    for i in range(0, 100):
        unix_time -= 1
        rssi += random.randint(-2, 2)

        if rssi > -50:
            rssi = -51
        elif rssi < -95:
            rssi = -94
        
        time_signal.append([unix_time, rssi])

    return time_signal