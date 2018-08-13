header_type meta_t {
    fields {
        tdelta : 32;
        int_inst_cnt : 16;
    }
}

header_type intrinsic_metadata_t {
    fields {
        ingress_global_tstamp : 32;
        egress_global_tstamp : 32;
        drop_counter_low : 32;
        drop_counter_high : 32;
    }
}

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
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}
/*
header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        length_ : 16;
        checksum : 16;
    }
}
//vxlan_gpe
header_type vxlan_gpe_t {
    fields {
        flags : 8;
        reserved : 16;S
        next_proto : 8;
        vni : 24;
        reserved2 : 8;
    }
}
//vxlan_gpe_int 
header_type vxlan_gpe_int_header_t {
    fields {
        int_type : 8;
        rsvd : 8;
        len : 8;
        next_proto : 8;
    }
}
*/

// INT headers
header_type int_header_t {
    fields {

        max_hop_cnt             : 8;
        total_hop_cnt           : 8;
    
    }
}

// INT meta-value headers - different header for each value type
// bos is index of parser to parse int_value or protocol_value 
header_type int_switch_id_header_t {
    fields {
        bos : 1;
        switch_id : 31;
    }
}


header_type int_ingress_port_id_header_t {
    fields {
        bos : 1;
        ingress_port_id : 31;
    }
}

header_type int_ingress_tstamp_header_t {
    fields {
        bos : 1;
        ingress_tstamp : 31;
    }
}

header_type int_egress_port_id_header_t {
    fields {
        bos : 1;
        egress_port_id : 31;
    }
}

header_type int_egress_tstamp_header_t {
    fields {
        bos : 1;
        egress_tstamp : 31;

    }
}
header_type int_drop_counter_header_t {
    fields {
        
        low :32;
        high : 32;
    }
}


//generic int value (info) header for extraction
header_type int_value_t {
    fields {
        bos : 1;
        value : 31;
    }
}
header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset :4;
        res : 3;
        ecn : 3;
        ctrl : 6;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
        
    }
    
} 
//rand 
/*
header_type rand_header_t {
    

}*/
header_type tcp_length_meta_t {
    fields {
        tcpLength : 16;
    }

}
metadata tcp_length_meta_t tcp_length_meta;
#define SWITCH_ID 0x01
header_type rand_meta_t {
    fields {
        sampling_ratio : 32;
        random_num : 32;
        sampling_random_num : 32;
    }
}
metadata rand_meta_t rand_meta;

