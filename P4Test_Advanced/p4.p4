header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}
header_type intrinsic_metadata_t {
    fields {
        mcast_grp : 4;
        egress_rid : 4;
        mcast_hash : 16;
        lf_field_list: 32;
    }
}

header_type cpu_header_t {
    fields {
        device: 8;
        reason: 8;
    }
}

header cpu_header_t cpu_header;

parser start {
    return select(current(0, 64)) {
        0 : parse_cpu_header;
        default: parse_ethernet;
    }
}

header ethernet_t ethernet;
metadata intrinsic_metadata_t intrinsic_metadata;

parser parse_ethernet {
    extract(ethernet);
    return ingress;
}

parser parse_cpu_header {
    extract(cpu_header);
    return parse_ethernet;
}

action _drop() {
    drop();
}

action _nop() {
}

#define CPU_MIRROR_SESSION_ID                  250

action do_copy_to_cpu() {
    clone_ingress_pkt_to_egress(CPU_MIRROR_SESSION_ID);
}

table copy_to_cpu {
    actions {do_copy_to_cpu;}
    size : 1;
}
action fwd(port) {
    modify_field(standard_metadata.egress_spec,port);
}
table fwd_table{
    reads {
        standard_metadata.clone_spec : exact;

    }
    actions {
        _drop;
        fwd;

    }
}

control ingress {
    
    apply(copy_to_cpu);
    //if(standard_metadata.clone_spec == 250){
      //  apply(fwd_table);
    //}
    apply(fwd_table);


}

action do_cpu_encap() {
    add_header(cpu_header);
    modify_field(cpu_header.device, 0);
    modify_field(cpu_header.reason, 0xab);
}

table redirect {
    reads { standard_metadata.instance_type : exact; }
    actions { _drop; do_cpu_encap; }
    size : 16;
}



control egress {
    apply(redirect);
   // apply(fwd_table);
   
    
}