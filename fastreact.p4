#include <core.p4>
#include <v1model.p4>


typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

typedef bit<8> sensor_id_t;
typedef bit<8> sensor_value_t;

enum bit<16> ethernet_kind {
  ipv4   = 0x800,
  sensor = 0x842
}

header ethernet_t {
  macAddr_t dstAddr;
  macAddr_t srcAddr;
  ethernet_kind etherType;
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


enum bit<3> op_t {
  invalid = 0,
  lt      = 1,
  le      = 2,
  gt      = 3,
  ge      = 4,
  eq      = 5,
  ne      = 6
}

const bit<8> maximum_number_of_rules = 10;
const bit<8> number_of_ors = 3;
const bit<8> number_of_ands = 4;

// DNF form:
// ((id00 op00 constant00)^(id01 op01 constant01)^(id02 op02 constant02)^(id03 op03 constant03))v
// ((id10 op10 constant10)^(id11 op11 constant11)^(id12 op12 constant12)^(id13 op13 constant13))v
// ((id20 op20 constant20)^(id21 op21 constant21)^(id22 op22 constant22)^(id23 op23 constant23))

// A rule is a DNF expression.
// That contains a sequence of disjuncts (at most number_of_ors one of them).
// Each disjunct is a conjunction of number_of_ands triplets.
// Where a triplet is the sensor id, operator and the value comparing against.
// If the corresponding operator has the value 'op_t.invalid' then that triplet and the rest of the triplets in the conjunction are invalid.
// If the first triplet of a disjunct is invalid, then that disjunct and the rest of the disjuncts are invalid.
// You can assume that each rule must have at least one valid triplet.
struct rule_t {
  sensor_id_t    id00;
  op_t           op00;
  sensor_value_t constant00;

  sensor_id_t    id01;
  op_t           op01;
  sensor_value_t constant01;

  sensor_id_t    id02;
  op_t           op02;
  sensor_value_t constant02;

  sensor_id_t    id03;
  op_t           op03;
  sensor_value_t constant03;

  sensor_id_t    id10;
  op_t           op10;
  sensor_value_t constant10;

  sensor_id_t    id11;
  op_t           op11;
  sensor_value_t constant11;

  sensor_id_t    id12;
  op_t           op12;
  sensor_value_t constant12;

  sensor_id_t    id13;
  op_t           op13;
  sensor_value_t constant13;

  sensor_id_t    id20;
  op_t           op20;
  sensor_value_t constant20;

  sensor_id_t    id21;
  op_t           op21;
  sensor_value_t constant21;

  sensor_id_t    id22;
  op_t           op22;
  sensor_value_t constant22;

  sensor_id_t    id23;
  op_t           op23;
  sensor_value_t constant23;
}

struct metadata {}

parser MyParser(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
  state parse_ethernet {
    packet.extract(hdr.ethernet);
    transition select(hdr.ethernet.etherType) {
      ethernet_kind.ipv4:   parse_ipv4;
      ethernet_kind.sensor: parse_ipv4_and_sensor_data;
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

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
  apply { }
}


bool eval_triplet(in sensor_value_t val, in op_t op, in sensor_value_t constant) {
  if (op == op_t.invalid)
    return false;
  if (op == op_t.lt)
    return val < constant;
  if (op == op_t.le)
    return val <= constant;
  if (op == op_t.gt)
    return val > constant;
  if (op == op_t.ge)
    return val >= constant;
  if (op == op_t.eq)
    return val == constant;
  // if (op == op_t.ne) // IT MUST BE THE NOT EQUAL BRANCH
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
    sensor_id_t id03, op_t op03, sensor_value_t constant03,
    sensor_id_t id10, op_t op10, sensor_value_t constant10,
    sensor_id_t id11, op_t op11, sensor_value_t constant11,
    sensor_id_t id12, op_t op12, sensor_value_t constant12,
    sensor_id_t id13, op_t op13, sensor_value_t constant13,
    sensor_id_t id20, op_t op20, sensor_value_t constant20,
    sensor_id_t id21, op_t op21, sensor_value_t constant21,
    sensor_id_t id22, op_t op22, sensor_value_t constant22,
    sensor_id_t id23, op_t op23, sensor_value_t constant23) {

    sensor_id_t sensor_id = hdr.sensordata.sensor_id;
    sensor_value_t sensor_value = hdr.sensordata.sensor_value;


    sensor_value_t val00 = id00 == sensor_id? sensor_value : lookup_cached_value(id00);
    sensor_value_t val01 = id01 == sensor_id? sensor_value : lookup_cached_value(id01);
    sensor_value_t val02 = id02 == sensor_id? sensor_value : lookup_cached_value(id02);
    sensor_value_t val03 = id03 == sensor_id? sensor_value : lookup_cached_value(id03);
    if (eval_triplet(val00, op00, constant00) &&
        eval_triplet(val01, op01, constant01) &&
        eval_triplet(val02, op02, constant02) &&
        eval_triplet(val03, op03, constant03)) {
      // rule triggered
      hdr.wittness.yesorno = 1;
      return;
    }


    // same block repeates NUMBER_OF_DISJS_OF_A_RULE times for each disjunction
    sensor_value_t val10 = id10 == sensor_id? sensor_value : lookup_cached_value(id10);
    sensor_value_t val11 = id11 == sensor_id? sensor_value : lookup_cached_value(id11);
    sensor_value_t val12 = id12 == sensor_id? sensor_value : lookup_cached_value(id12);
    sensor_value_t val13 = id13 == sensor_id? sensor_value : lookup_cached_value(id13);
    if (eval_triplet(val10, op10, constant10) &&
        eval_triplet(val11, op11, constant11) &&
        eval_triplet(val12, op12, constant12) &&
        eval_triplet(val13, op13, constant13)) {
      // rule triggered
      hdr.wittness.yesorno = 1;
      return;
    }

    sensor_value_t val20 = id20 == sensor_id? sensor_value : lookup_cached_value(id20);
    sensor_value_t val21 = id21 == sensor_id? sensor_value : lookup_cached_value(id21);
    sensor_value_t val22 = id22 == sensor_id? sensor_value : lookup_cached_value(id22);
    sensor_value_t val23 = id23 == sensor_id? sensor_value : lookup_cached_value(id23);
    if (eval_triplet(val20, op20, constant20) &&
        eval_triplet(val21, op21, constant21) &&
        eval_triplet(val22, op22, constant22) &&
        eval_triplet(val23, op23, constant23)) {
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
    size = maximum_number_of_rules;
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

control MyDeparser(packet_out packet, in headers hdr) {
  apply {
    packet.emit(hdr.ethernet);
    packet.emit(hdr.ipv4);
    packet.emit(hdr.wittness);
  }
}

V1Switch(MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;
