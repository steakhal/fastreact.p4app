#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from scapy.all import *


class SensorData(Packet):
  fields_desc = [
    ByteField("sensor_id", 0),
    ByteField("sensor_value", 0),
  ]

bind_layers(Ether, SensorData, type=0x842)
