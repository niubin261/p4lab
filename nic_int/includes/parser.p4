metadata meta_t meta;
metadata intrinsic_metadata_t intrinsic_metadata;

parser start {
    return parse_ethernet;
}

/*
 * Ethernet
 */

#define ETHERTYPE_IPV4 0x0800

header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4;
        default : ingress;
    }
}

/*
 * IPv4
 */



header ipv4_t ipv4;

#define IP_PROTOCOLS_TCP 0x06
#define IP_PROTOCOLS_INT 0xfe
parser parse_ipv4 {
    extract(ipv4);
    set_metadata(tcp_length_meta.tcpLength,ipv4.totalLen - 20);
    return select(latest.protocol) {
        IP_PROTOCOLS_TCP : parse_tcp;
        IP_PROTOCOLS_INT : parse_int_header;
        default : ingress;
    }
}

/*
 * UDP
 */
/*
#define UDP_PORT_VXLAN_GPE             4790

header udp_t udp;

parser parse_udp {
    extract(udp);

    return select(latest.dstPort) {
        UDP_PORT_VXLAN_GPE : parse_vxlan_gpe;
        default: ingress;
    }

}
*/

/*
 * INT
 */
/*
#define VXLAN_GPE_NEXT_PROTO_INT        0x05 

header vxlan_gpe_t vxlan_gpe;

parser parse_vxlan_gpe {
    extract(vxlan_gpe);
    return select(vxlan_gpe.next_proto) {
        VXLAN_GPE_NEXT_PROTO_INT : parse_gpe_int_header;
        default : ingress;
    }
}
*/
header int_header_t                             int_header;
header int_switch_id_header_t                   int_switch_id_header;

header int_ingress_port_id_header_t             int_ingress_port_id_header;

header int_ingress_tstamp_header_t              int_ingress_tstamp_header;
header int_egress_port_id_header_t              int_egress_port_id_header;

header int_egress_tstamp_header_t               int_egress_tstamp_header;
header int_drop_counter_header_t                int_drop_counter_header;
//header vxlan_gpe_int_header_t                   vxlan_gpe_int_header;
#define MAX_INT_INFO                            15
header int_value_t                              int_value[MAX_INT_INFO];
header tcp_t                                    tcp;
/*
parser parse_gpe_int_header {
    // GPE uses a shim header to preserve the next_protocol field
    extract(vxlan_gpe_int_header);
    return parse_int_header;
}
*/
parser parse_int_header {
    extract(int_header);
    set_metadata(meta.int_inst_cnt, int_header.total_hop_cnt);
    return select (latest.max_hop_cnt, latest.total_hop_cnt) {

        // reserved bits = 0 and total_hop_cnt == 0
        // no int_values are added by upstream
       

        // parse INT val headers added by upstream devices (total_hop_cnt != 0)
        // reserved bits must be 0
        0xff mask 0x00 : parse_int_val;

        0x00 mask 0x00 : ingress;
        // never transition to the following state
        default: parse_all_int_meta_value_headers;
    }
}

parser parse_int_val {
    extract(int_value[next]);
    return select(latest.bos) {
        0 : parse_int_val;
        1 : parse_tcp;
    }
}

parser parse_tcp {
    extract(tcp);
    return ingress;

}
parser parse_all_int_meta_value_headers {
    // bogus state.. just extract all possible int headers in the
    // correct order to build
    // the correct parse graph for deparser (while adding headers)
    
    extract(int_drop_counter_header);
    extract(int_ingress_port_id_header);
    extract(int_ingress_tstamp_header);
    extract(int_egress_port_id_header);
    extract(int_egress_tstamp_header);
    extract(int_switch_id_header);
    return parse_int_val;
}



//field_list_calculation
field_list ipv4_checksum_list {
        ipv4.version;
        ipv4.ihl;
        ipv4.diffserv;
        ipv4.totalLen;
        ipv4.identification;
        ipv4.flags;
        ipv4.fragOffset;
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
    verify ipv4_checksum if (ipv4.ihl == 5);
    update ipv4_checksum if (ipv4.ihl == 5);
}


field_list tcp_checksum_list {
       
    ipv4.srcAddr;
    ipv4.dstAddr;
    8'0;
    ipv4.protocol;
    tcp_length_meta.tcpLength;
    tcp.srcPort;
    tcp.dstPort;
    tcp.seqNo;
    tcp.ackNo;
    tcp.dataOffset;
    tcp.res;
    tcp.ecn;
    tcp.ctrl;
    tcp.window;
    tcp.urgentPtr;
    payload;
}
field_list_calculation tcp_checksum {
    input {
        tcp_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field tcp.checksum {
    verify tcp_checksum if(valid(ipv4));
    update tcp_checksum if(valid(ipv4));
    
} 