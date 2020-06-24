#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import time
from scapy.all import *
from sensor_headers import SensorData


def main():
  iface = conf.iface
  # TODO: currently it sends an example sensor data packet to the 'h2' node
  sensor_pkt = Ether(dst='00:04:00:00:00:01', src=get_if_hwaddr(iface)) / \
               SensorData(sensor_id=4, sensor_value=6) / \
               IP(dst='10.0.1.10')

  while True:
    try:
      print("sending packet over {}".format(iface))
      sendp(sensor_pkt, iface=iface)
      time.sleep(1)
    except KeyboardInterrupt:
      sys.exit()

if __name__ == '__main__':
  main()
