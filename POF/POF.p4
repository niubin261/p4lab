header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }

}
header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        frag : 16;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}
header ethernet_t ethernet;
header ipv4_t ipv4;
parser start {
    return parse_ethernet ;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0x0800 : parse_ipv4;
        default: ingress;
    }
}
field_list ipv4_checksum_list {
        ipv4.version;
        ipv4.ihl;
        ipv4.diffserv;
        ipv4.totalLen;
        ipv4.identification;       
        ipv4.frag;
        ipv4.ttl;
        ipv4.protocol;
        ipv4.srcAddr;
               
        ipv4.dstAddr;
}
field_list_calculation ipv4_checksum {
    input {
        ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field ipv4.hdrChecksum  {
    verify ipv4_checksum;
    update ipv4_checksum;
}
parser parse_ipv4 {
    extract(ipv4);
    return ingress;
    
}

action _hit(port){
    modify_field(standard_metadata.egress_spec,port);

}
action _miss(port){
    modify_field(standard_metadata.egress_spec,port);
}
action _drop(){
    drop();
}
table fwd_tbl {
    reads {
        ipv4 : valid;
        ipv4.srcAddr : ternary;
        ipv4.dstAddr : ternary;
        

    }
    actions {
        _hit;
        _miss;
        _drop;    
    }
    size : 100;
    

}
control ingress {
    apply(fwd_tbl);


}
control egress {


}








