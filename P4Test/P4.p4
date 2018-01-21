header_type eth_hdr {
    fields {
        dst : 48;
        src : 48;
        etype : 16;
    }
}
//header
header_type ipv4_hdr {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flag : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr : 32;
    }
}
header ipv4_hdr ipv4;
header eth_hdr eth;
parser start {
    return eth_parser;
}
parser eth_parser {
    extract(eth);

    return select(latest.etype) {
        0x0800 : ipv4_parser;
        default : ingress;
    }
}
parser ipv4_parser {
    extract(ipv4);
    return ingress;


}
action drop_act() {
   drop();
}
action forward_act(port) {
    
    modify_field(standard_metadata.egress_spec,port);
    
}

table fwd_table {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
  //      drop_act;
        forward_act;
        drop_act;
    }
}
control ingress {
    apply(fwd_table);
}
control egress{

}
