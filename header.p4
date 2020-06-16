#ifndef __HEADER_P4__
#define __HEADER_P4__ 1

struct ingress_metadata_t {
    bit<32> nhop_ipv4;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}


// ((S1 < 50)v(S2 > 25))^(S3 = 10)
struct rule_t {
  int<8> sensor_id000;
  int<8> opcode000;
  int<8> constant_value000;
  
  int<8> sensor_id001;
  int<8> opcode001;
  int<8> constant_value001;
  
  int<8> sensor_id002;
  int<8> opcode002;
  int<8> constant_value002;
  
  
  int<8> sensor_id010;
  int<8> opcode010;
  int<8> constant_value010;
  
  int<8> sensor_id011;
  int<8> opcode011;
  int<8> constant_value011;
  
  int<8> sensor_id012;
  int<8> opcode012;
  int<8> constant_value012;
  
  
  int<8> sensor_id020;
  int<8> opcode020;
  int<8> constant_value020;
  
  int<8> sensor_id021;
  int<8> opcode021;
  int<8> constant_value021;
  
  int<8> sensor_id022;
  int<8> opcode022;
  int<8> constant_value022;
}

struct metadata {
    @name("ingress_metadata")
    ingress_metadata_t   ingress_metadata;
}

header sensor_data {
    int<8> sensor_id;
    int<8> sensor_value;
}

struct headers {
    @name("ethernet")
    ethernet_t ethernet;
    @name("ipv4")
    ipv4_t     ipv4;
    
    sensor_data sensordata;
}

#endif // __HEADER_P4__
