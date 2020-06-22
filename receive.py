#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from scapy.all import *


def expand(x):
  yield x
  while x.payload:
    x = x.payload
    yield x

def handle_pkt(pkt):
  print('called handle_pkt: ', end='')
  print(pkt)
  # TODO: pretty print the received packet
  # note that the very last byte is the 'result'

def main():
  iface = conf.iface
  print("sniffing on {}".format(iface))
  sniff(iface=iface, prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
  main()
