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




#define NUMBER_OF_RULES 1
#define NUMBER_OF_CONJS_OF_A_RULE 3
#define NUMBER_OF_DISJS_OF_A_RULE 3

#define SENSOR_VALUE_BITWIDTH 8
#define SENSOR_ID_BITWIDTH 8

#define OP_BITWIDTH 3
#define OP_INVALID 0
#define OP_LT 1
#define OP_LE 2
#define OP_GT 3
#define OP_GE 4
#define OP_EQ 5
#define OP_NE 6

#define TRIPLET_BIT_WIDTH ((SENSOR_ID_BITWIDTH) + (OP_BITWIDTH) + (SENSOR_VALUE_BITWIDTH))
#define RULE_BITWIDTH ((NUMBER_OF_CONJS_OF_A_RULE) * (NUMBER_OF_DISJS_OF_A_RULE) * (TRIPLET_BIT_WIDTH))

typedef bit<SENSOR_ID_BITWIDTH> sensor_id_t;
typedef bit<OP_BITWIDTH> op_t;
typedef bit<SENSOR_VALUE_BITWIDTH> sensor_value_t;
typedef bit<RULE_BITWIDTH> bitrule_t;

// DNF form
// ((S1 < 50)^(S2 > 25))v(S3 = 10)
struct rule_t {
  sensor_id_t    sensor_id000;
  op_t           opcode000;
  sensor_value_t constant_value000;
  
  sensor_id_t    sensor_id001;
  op_t           opcode001;
  sensor_value_t constant_value001;
  
  sensor_id_t    sensor_id002;
  op_t           opcode002;
  sensor_value_t constant_value002;
  
  
  sensor_id_t    sensor_id010;
  op_t           opcode010;
  sensor_value_t constant_value010;
  
  sensor_id_t    sensor_id011;
  op_t           opcode011;
  sensor_value_t constant_value011;
  
  sensor_id_t    sensor_id012;
  op_t           opcode012;
  sensor_value_t constant_value012;
  
  
  sensor_id_t    sensor_id020;
  op_t           opcode020;
  sensor_value_t constant_value020;
  
  sensor_id_t    sensor_id021;
  op_t           opcode021;
  sensor_value_t constant_value021;
  
  sensor_id_t    sensor_id022;
  op_t           opcode022;
  sensor_value_t constant_value022;
}

struct metadata {
    @name("ingress_metadata")
    ingress_metadata_t   ingress_metadata;
}

header sensor_data {
    sensor_id_t sensor_id;
    sensor_value_t sensor_value;
}

struct headers {
    @name("ethernet")
    ethernet_t ethernet;
    @name("ipv4")
    ipv4_t     ipv4;
    
    sensor_data sensordata;
}

#endif // __HEADER_P4__
