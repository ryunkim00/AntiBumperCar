import requests
import serial

import time


print("TEST")
i = 0
ser = serial.Serial('COM5', 9600, timeout=1)

while True:
    r = requests.get("https://gtipold.api.stdlib.com/HackThe6ix@dev/")
    message = r.text
    ser.write(message.encode())
    print(message)
