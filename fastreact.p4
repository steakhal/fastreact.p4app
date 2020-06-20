#include <core.p4>
#include <v1model.p4>

/*
************************************************************************
*********************** H E A D E R S **********************************
************************************************************************
*/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
  macAddr_t dstAddr;
  macAddr_t srcAddr;
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
  ip4Addr_t srcAddr;
  ip4Addr_t dstAddr;
}


// TODO: maybe use 'const bit<32>' type instead of macros?
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

struct metadata {}

header sensor_data {
  sensor_id_t sensor_id;
  sensor_value_t sensor_value;
}

header did_trigger {
  bit<32> yesorno;
}

struct headers {
  ethernet_t ethernet;
  ipv4_t ipv4;
  sensor_data sensordata;
  did_trigger wittness; // TODO: proof of concept that it can evaluate a given rule
}


/*
************************************************************************
*********************** P A R S E R ************************************
************************************************************************
*/

parser MyParser(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
  state parse_ethernet {
    packet.extract(hdr.ethernet);
    transition select(hdr.ethernet.etherType) {
      0x800: parse_ipv4;
      0x801: parse_ipv4_and_sensor_data;
      default: accept;
    }
  }

  state parse_ipv4 {
    packet.extract(hdr.ipv4);
    transition accept;
  }
  state parse_ipv4_and_sensor_data {
    packet.extract(hdr.ipv4);
    packet.extract(hdr.sensordata);
    transition accept;
  }

  state start {
    transition parse_ethernet;
  }
}

control MyDeparser(packet_out packet, in headers hdr) {
  apply {
    packet.emit(hdr.ethernet);
    packet.emit(hdr.ipv4);
    packet.emit(hdr.wittness);
  }
}

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
  apply { }
}

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
  apply {
    update_checksum(
      hdr.ipv4.isValid(),
      {
        hdr.ipv4.version,
        hdr.ipv4.ihl,
        hdr.ipv4.diffserv,
        hdr.ipv4.totalLen,
        hdr.ipv4.identification,
        hdr.ipv4.flags,
        hdr.ipv4.fragOffset,
        hdr.ipv4.ttl,
        hdr.ipv4.protocol,
        hdr.ipv4.srcAddr,
        hdr.ipv4.dstAddr
      },
      hdr.ipv4.hdrChecksum,
      HashAlgorithm.csum16);
  }
}


bool eval_triplet(in sensor_value_t val, in op_t op, in sensor_value_t constant) {
  if (op == OP_INVALID)
    return false;
  if (op == OP_LT)
    return val < constant;
  if (op == OP_LE)
    return val <= constant;
  if (op == OP_GT)
    return val > constant;
  if (op == OP_GE)
    return val >= constant;
  if (op == OP_EQ)
    return val == constant;
  // if (op == OP_NE) // IT MUST BE THE NOT EQUAL BRANCH
  return val != constant;
}

sensor_value_t lookup_cached_value(in sensor_id_t id) {
  // TODO: implement this
  return 42;
}

control MyIngress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action drop() {
      mark_to_drop(standard_metadata);
    }

    action apply_rule(
      sensor_id_t id00, op_t op00, sensor_value_t constant00,
      sensor_id_t id01, op_t op01, sensor_value_t constant01,
      sensor_id_t id02, op_t op02, sensor_value_t constant02,
      sensor_id_t id10, op_t op10, sensor_value_t constant10,
      sensor_id_t id11, op_t op11, sensor_value_t constant11,
      sensor_id_t id12, op_t op12, sensor_value_t constant12,
      sensor_id_t id20, op_t op20, sensor_value_t constant20,
      sensor_id_t id21, op_t op21, sensor_value_t constant21,
      sensor_id_t id22, op_t op22, sensor_value_t constant22) {

      sensor_id_t sensor_id = hdr.sensordata.sensor_id;
      sensor_value_t sensor_value = hdr.sensordata.sensor_value;

      // DNF form
      // ((S1 < 50)^(S2 > 25))v(S3 = 10)

      // evaluate all the variable references of the first disjunctive group
      // there will be NUMBER_OF_CONJS_OF_A_RULE one of them
      sensor_value_t val00 = id00 == sensor_id? sensor_value : lookup_cached_value(id00);
      sensor_value_t val01 = id01 == sensor_id? sensor_value : lookup_cached_value(id01);
      sensor_value_t val02 = id02 == sensor_id? sensor_value : lookup_cached_value(id02);
      if (eval_triplet(val00, op00, constant00) &&
          eval_triplet(val01, op01, constant01) &&
          eval_triplet(val02, op02, constant02)) {
        // rule triggered
        hdr.wittness.yesorno = 1;
        return;
      }


      // same block repeates NUMBER_OF_DISJS_OF_A_RULE times for each disjunction
      sensor_value_t val10 = id10 == sensor_id? sensor_value : lookup_cached_value(id10);
      sensor_value_t val11 = id11 == sensor_id? sensor_value : lookup_cached_value(id11);
      sensor_value_t val12 = id12 == sensor_id? sensor_value : lookup_cached_value(id12);
      if (eval_triplet(val10, op10, constant10) &&
          eval_triplet(val11, op11, constant11) &&
          eval_triplet(val12, op12, constant12)) {
        // rule triggered
        hdr.wittness.yesorno = 1;
        return;
      }

      sensor_value_t val20 = id20 == sensor_id? sensor_value : lookup_cached_value(id20);
      sensor_value_t val21 = id21 == sensor_id? sensor_value : lookup_cached_value(id21);
      sensor_value_t val22 = id22 == sensor_id? sensor_value : lookup_cached_value(id22);
      if (eval_triplet(val20, op20, constant20) &&
          eval_triplet(val21, op21, constant21) &&
          eval_triplet(val22, op22, constant22)) {
        // rule triggered
        hdr.wittness.yesorno = 1;
        return;
      }

      // rule did not trigger
      hdr.wittness.yesorno = 0;
    }

    table sensor_to_rule_mapping {
      actions = {
        apply_rule;
        NoAction;
      }
      key = {
        hdr.sensordata.sensor_id: exact;
      }
      size = 16; // at most 16 sensors
      default_action = NoAction();
    }


    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
      standard_metadata.egress_spec = port;
      hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
      hdr.ethernet.dstAddr = dstAddr;
      hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    table ipv4_lpm {
      key = {
        hdr.ipv4.dstAddr: lpm;
      }
      actions = {
        ipv4_forward;
        drop;
        NoAction;
      }
      size = 1024;
      default_action = drop();
    }

    apply {
      if (hdr.sensordata.isValid())
        sensor_to_rule_mapping.apply();
      if (hdr.ipv4.isValid())
        ipv4_lpm.apply();
    }
}

control MyEgress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
  apply { }
}


V1Switch(MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;
