#include <core.p4>
#include <v1model.p4>

#include "header.p4"
#include "parser.p4"

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

bool eval_rule_for_packet(in sensor_id_t sensor_id, in sensor_value_t sensor_value, in bitrule_t r) {
  // parse all fields of the rule
  sensor_id_t sensor_id00 = (sensor_id_t)(r >> (0*TRIPLET_BIT_WIDTH + OP_BITWIDTH + SENSOR_VALUE_BITWIDTH));
  sensor_id_t sensor_id01 = (sensor_id_t)(r >> (1*TRIPLET_BIT_WIDTH + OP_BITWIDTH + SENSOR_VALUE_BITWIDTH));
  sensor_id_t sensor_id02 = (sensor_id_t)(r >> (2*TRIPLET_BIT_WIDTH + OP_BITWIDTH + SENSOR_VALUE_BITWIDTH));
  sensor_id_t sensor_id10 = (sensor_id_t)(r >> (3*TRIPLET_BIT_WIDTH + OP_BITWIDTH + SENSOR_VALUE_BITWIDTH));
  sensor_id_t sensor_id11 = (sensor_id_t)(r >> (4*TRIPLET_BIT_WIDTH + OP_BITWIDTH + SENSOR_VALUE_BITWIDTH));
  sensor_id_t sensor_id12 = (sensor_id_t)(r >> (5*TRIPLET_BIT_WIDTH + OP_BITWIDTH + SENSOR_VALUE_BITWIDTH));
  sensor_id_t sensor_id20 = (sensor_id_t)(r >> (6*TRIPLET_BIT_WIDTH + OP_BITWIDTH + SENSOR_VALUE_BITWIDTH));
  sensor_id_t sensor_id21 = (sensor_id_t)(r >> (7*TRIPLET_BIT_WIDTH + OP_BITWIDTH + SENSOR_VALUE_BITWIDTH));
  sensor_id_t sensor_id22 = (sensor_id_t)(r >> (8*TRIPLET_BIT_WIDTH + OP_BITWIDTH + SENSOR_VALUE_BITWIDTH));

  op_t opcode00 = (op_t)(r >> (0*TRIPLET_BIT_WIDTH + SENSOR_VALUE_BITWIDTH));
  op_t opcode01 = (op_t)(r >> (1*TRIPLET_BIT_WIDTH + SENSOR_VALUE_BITWIDTH));
  op_t opcode02 = (op_t)(r >> (2*TRIPLET_BIT_WIDTH + SENSOR_VALUE_BITWIDTH));
  op_t opcode10 = (op_t)(r >> (3*TRIPLET_BIT_WIDTH + SENSOR_VALUE_BITWIDTH));
  op_t opcode11 = (op_t)(r >> (4*TRIPLET_BIT_WIDTH + SENSOR_VALUE_BITWIDTH));
  op_t opcode12 = (op_t)(r >> (5*TRIPLET_BIT_WIDTH + SENSOR_VALUE_BITWIDTH));
  op_t opcode20 = (op_t)(r >> (6*TRIPLET_BIT_WIDTH + SENSOR_VALUE_BITWIDTH));
  op_t opcode21 = (op_t)(r >> (7*TRIPLET_BIT_WIDTH + SENSOR_VALUE_BITWIDTH));
  op_t opcode22 = (op_t)(r >> (8*TRIPLET_BIT_WIDTH + SENSOR_VALUE_BITWIDTH));

  sensor_value_t constant_value00 = (sensor_value_t)(r >> (0*TRIPLET_BIT_WIDTH));
  sensor_value_t constant_value01 = (sensor_value_t)(r >> (1*TRIPLET_BIT_WIDTH));
  sensor_value_t constant_value02 = (sensor_value_t)(r >> (2*TRIPLET_BIT_WIDTH));
  sensor_value_t constant_value10 = (sensor_value_t)(r >> (3*TRIPLET_BIT_WIDTH));
  sensor_value_t constant_value11 = (sensor_value_t)(r >> (4*TRIPLET_BIT_WIDTH));
  sensor_value_t constant_value12 = (sensor_value_t)(r >> (5*TRIPLET_BIT_WIDTH));
  sensor_value_t constant_value20 = (sensor_value_t)(r >> (6*TRIPLET_BIT_WIDTH));
  sensor_value_t constant_value21 = (sensor_value_t)(r >> (7*TRIPLET_BIT_WIDTH));
  sensor_value_t constant_value22 = (sensor_value_t)(r >> (8*TRIPLET_BIT_WIDTH));

  // DNF form
  // ((S1 < 50)^(S2 > 25))v(S3 = 10)

  // evaluate all the variable references of the first disjunctive group
  // there will be NUMBER_OF_CONJS_OF_A_RULE one of them
  sensor_value_t val00 = sensor_id00 == sensor_id? sensor_value : lookup_cached_value(sensor_id00);
  sensor_value_t val01 = sensor_id01 == sensor_id? sensor_value : lookup_cached_value(sensor_id01);
  sensor_value_t val02 = sensor_id02 == sensor_id? sensor_value : lookup_cached_value(sensor_id02);
  if (eval_triplet(val00, opcode00, constant_value00) &&
      eval_triplet(val01, opcode01, constant_value01) &&
      eval_triplet(val02, opcode02, constant_value02))
    return true;


  // same block repeates NUMBER_OF_DISJS_OF_A_RULE times for each disjunction
  sensor_value_t val10 = sensor_id10 == sensor_id? sensor_value : lookup_cached_value(sensor_id10);
  sensor_value_t val11 = sensor_id11 == sensor_id? sensor_value : lookup_cached_value(sensor_id11);
  sensor_value_t val12 = sensor_id12 == sensor_id? sensor_value : lookup_cached_value(sensor_id12);
  if (eval_triplet(val10, opcode10, constant_value10) &&
      eval_triplet(val11, opcode11, constant_value11) &&
      eval_triplet(val12, opcode12, constant_value12))
    return true;

  sensor_value_t val20 = sensor_id20 == sensor_id? sensor_value : lookup_cached_value(sensor_id20);
  sensor_value_t val21 = sensor_id21 == sensor_id? sensor_value : lookup_cached_value(sensor_id21);
  sensor_value_t val22 = sensor_id22 == sensor_id? sensor_value : lookup_cached_value(sensor_id22);
  if (eval_triplet(val20, opcode20, constant_value20) &&
      eval_triplet(val21, opcode21, constant_value21) &&
      eval_triplet(val22, opcode22, constant_value22))
    return true;
  return false;
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action apply_rule(bitrule_t r) {
      if (eval_rule_for_packet(hdr.sensordata.sensor_id, hdr.sensordata.sensor_value, r)) {
        // if rule hits
      } else {
        // does not hit
      }
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
    apply {
        if (hdr.ipv4.isValid()) {
            sensor_to_rule_mapping.apply();
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action rewrite_mac(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
    }
    action _drop() {
        mark_to_drop(standard_metadata);
    }
    table send_frame {
        actions = {
            rewrite_mac;
            _drop;
            NoAction;
        }
        key = {
            standard_metadata.egress_port: exact;
        }
        size = 256;
        default_action = NoAction();
    }
    apply {
        if (hdr.ipv4.isValid()) {
          send_frame.apply();
        }
    }
}
/*
control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action _drop() {
        mark_to_drop(standard_metadata);
    }
    action set_nhop(bit<32> nhop_ipv4, bit<9> port) {
        meta.ingress_metadata.nhop_ipv4 = nhop_ipv4;
        standard_metadata.egress_spec = port;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    action set_dmac(bit<48> dmac) {
        hdr.ethernet.dstAddr = dmac;
    }
    table ipv4_lpm {
        actions = {
            _drop;
            set_nhop;
            NoAction;
        }
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        size = 1024;
        default_action = NoAction();
    }
    table forward {
        actions = {
            set_dmac;
            _drop;
            NoAction;
        }
        key = {
            meta.ingress_metadata.nhop_ipv4: exact;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (hdr.ipv4.isValid()) {
          ipv4_lpm.apply();
          forward.apply();
        }
    }
}*/

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
