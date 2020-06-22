#include <core.p4>
#include <v1model.p4>


typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

// Change these values according to the value reprentations of the problem domain.
typedef bit<8>  sensor_id_t;
typedef bit<8>  sensor_value_t;

// Simple state machine representing the result of matching rules.
enum bit<8> rule_match_kind {
  no_match_initiated = 0, // no rule lookup happened
  no_rule_found      = 1, // lookup happened but no rule defined for the given sensor id
  evaluated_to_true  = 2, // lookup happened and the corresponding rule evaluated to true
  evaluated_to_false = 3  // same as above but evaluated to false
}

// It carries information from MyIngress to MyEgress
struct metadata {
  rule_match_kind match;
}

enum bit<16> ethernet_kind {
  ipv4   = 0x800,
  sensor = 0x842 // dummy ethernet type representing the sensor packets
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

// Represents a sensor measurement.
header sensor_data {
  sensor_id_t sensor_id; // the identifier of the producer sensor (it is used by the id## fields of a rule)
  sensor_value_t sensor_value;
}

// Dummy header, which serves debugging purposes.
// It is appended to the end of the outgoing packet, showing the state of
// the rule matching logic resulted by the implementation.
header rule_match_result {
  rule_match_kind match;
}

struct headers {
  ethernet_t ethernet;
  ipv4_t ipv4;
  sensor_data sensordata;
  rule_match_result result;
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

const bit<32> maximum_number_of_sensors = 7;
const bit<32> maximum_number_of_rules = 10;
const bit<32> number_of_ors = 3;
const bit<32> number_of_ands = 4;

// DNF form:
// ((id00 op00 constant00)^(id01 op01 constant01)^(id02 op02 constant02)^(id03 op03 constant03))v
// ((id10 op10 constant10)^(id11 op11 constant11)^(id12 op12 constant12)^(id13 op13 constant13))v
// ((id20 op20 constant20)^(id21 op21 constant21)^(id22 op22 constant22)^(id23 op23 constant23))
// each left operand is a variable identifier which is resolved to the last sensor value corresponding to that sensor id
// each right operand is a simple numeric constant

// A rule is a DNF expression.
// That contains a sequence of disjuncts (at most number_of_ors one of them).
// Each disjunct is a conjunction of number_of_ands triplets.
// Where a triplet is the sensor id, operator and the value comparing against.
// If the corresponding operator has the value 'op_t.invalid' then that triplet and the rest of the triplets in the conjunction are invalid.
// If the first triplet of a disjunct is invalid, then that disjunct and the rest of the disjuncts are invalid.
// You can assume that each rule must have at least one valid triplet.
struct rule_t {
  // note: unfortunately nested structs are not yet implemented by the p4 compiler, so unrolled this by hand
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

parser MyParser(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
  state parse_ethernet {
    packet.extract(hdr.ethernet);
    transition select(hdr.ethernet.etherType) {
      ethernet_kind.ipv4:   parse_ipv4;
      ethernet_kind.sensor: parse_sensor_data;
      default: accept;
    }
  }

  state parse_ipv4 {
    packet.extract(hdr.ipv4);
    transition accept;
  }
  state parse_sensor_data {
    packet.extract(hdr.sensordata);
    transition parse_ipv4;
  }

  state start {
    transition parse_ethernet;
  }
}

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
  apply { }
}

bool isOpValid(in op_t op) {
  return op != op_t.invalid;
}

// precondition: call only on valid triplets (op != op_t.invalid)
bool eval_triplet(in sensor_value_t val, in op_t op, in sensor_value_t constant) {
  // assuming valid op
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


control MyIngress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
  // Stores the very last sensor value of a given sensor id.
  // note: by default/initially each sensor id maps to zero value
  register<sensor_value_t>(maximum_number_of_sensors) sensor_history;

  action drop() {
    mark_to_drop(standard_metadata);
  }

  action default_handler() {
    meta.match = rule_match_kind.no_rule_found;
  }

  // sets 'meta.match' to either 'evaluated_to_true' or 'evaluated_to_false'
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

    // save current sensor value
    sensor_history.write((bit<32>)hdr.sensordata.sensor_id, hdr.sensordata.sensor_value);

    sensor_value_t value00;
    sensor_value_t value01;
    sensor_value_t value02;
    sensor_value_t value03;
    sensor_value_t value10;
    sensor_value_t value11;
    sensor_value_t value12;
    sensor_value_t value13;
    sensor_value_t value20;
    sensor_value_t value21;
    sensor_value_t value22;
    sensor_value_t value23;

    // unfortunately we can not read registers after a branch happened,
    // so we have to read ahead every values since that would be probably needed
    sensor_history.read(value00, (bit<32>)id00);
    sensor_history.read(value01, (bit<32>)id01);
    sensor_history.read(value02, (bit<32>)id02);
    sensor_history.read(value03, (bit<32>)id03);
    sensor_history.read(value10, (bit<32>)id10);
    sensor_history.read(value11, (bit<32>)id11);
    sensor_history.read(value12, (bit<32>)id12);
    sensor_history.read(value13, (bit<32>)id13);
    sensor_history.read(value20, (bit<32>)id20);
    sensor_history.read(value21, (bit<32>)id21);
    sensor_history.read(value22, (bit<32>)id22);
    sensor_history.read(value23, (bit<32>)id23);

    // when a triplet is invalid, simply ignore that
    // since the true is the identity value for the '&&' operation
    // note that the order of triplets is irrelevalnt
    // note that if no triplet is valid, then the rule is evaluated to true for every input

    bool group0 = (!isOpValid(op00) || eval_triplet(value00, op00, constant00)) &&
                  (!isOpValid(op01) || eval_triplet(value01, op01, constant01)) &&
                  (!isOpValid(op02) || eval_triplet(value02, op02, constant02)) &&
                  (!isOpValid(op03) || eval_triplet(value03, op03, constant03));
    bool group1 = (!isOpValid(op10) || eval_triplet(value10, op10, constant10)) &&
                  (!isOpValid(op11) || eval_triplet(value11, op11, constant11)) &&
                  (!isOpValid(op12) || eval_triplet(value12, op12, constant12)) &&
                  (!isOpValid(op13) || eval_triplet(value13, op13, constant13));
    bool group2 = (!isOpValid(op20) || eval_triplet(value20, op20, constant20)) &&
                  (!isOpValid(op21) || eval_triplet(value21, op21, constant21)) &&
                  (!isOpValid(op22) || eval_triplet(value22, op22, constant22)) &&
                  (!isOpValid(op23) || eval_triplet(value23, op23, constant23));

    meta.match = (group0 || group1 || group2) ? rule_match_kind.evaluated_to_true
                                              : rule_match_kind.evaluated_to_false;
  }

  table sensor_to_rule_mapping {
    actions = {
      default_handler;
      apply_rule;
    }
    key = {
      hdr.sensordata.sensor_id: exact;
    }
    size = maximum_number_of_rules;
    default_action = default_handler();
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
    meta.match = rule_match_kind.no_match_initiated;
    if (hdr.sensordata.isValid())
      sensor_to_rule_mapping.apply();
    if (hdr.ipv4.isValid())
      ipv4_lpm.apply();
  }
}

control MyEgress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
  apply {
    if (meta.match != rule_match_kind.no_match_initiated) {
      hdr.result.setValid();
      hdr.result.match = meta.match;
    }
  }
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
    // note: we no longer emit the sensordata, only the match result
    packet.emit(hdr.ethernet);
    packet.emit(hdr.ipv4);
    packet.emit(hdr.result);
  }
}

V1Switch(MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;
