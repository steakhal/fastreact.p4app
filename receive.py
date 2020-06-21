#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from scapy.all import *
from sensor_headers import SensorData

def expand(x):
  yield x
  while x.payload:
    x = x.payload
    yield x

def handle_pkt(pkt):
  if SensorData in pkt:
    data_layers = [l for l in expand(pkt) if l.name=='SensorData']
    print("")
    for sw in data_layers:
      print("something happening 4545454545")

def main():
  iface = conf.iface
  print("sniffing on {}".format(iface))
  sniff(iface=iface, prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
  main()
