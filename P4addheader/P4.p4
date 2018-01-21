header_type ethernet_t {
    fields{
        dstAddr : 32;
        srcAddr : 32;
        ethertype : 16;   
    }

}
header_type vlan_t {
    fields{
        pcp :3;
        cfi :1;
        vid :12;
        ethertype :16;
    }
    
}
header ethernet_t ethernet;
header vlan_t vlan;
parser start {
    return parser_ethernet;
}
parser parser_ethernet {
    extract(ethernet);
    return select(ethernet.ethertype){
        0x8100 : parser_vlan;
        default : ingress;    
    }

}
parser parser_vlan {
    extract(vlan);
    return ingress;
    
}

action add_vlan(){
    modify_field(ethernet.ethertype,0x8100);
    add_header(vlan);
    modify_field(vlan.pcp,0);
    modify_field(vlan.cfi,0);
    modify_field(vlan.vid,0);
    modify_field(vlan.ethertype,0x0800);
}
table add_vlan_tbl{


        actions {
            add_vlan;
        }
}
action do_fwd(port){
    modify_field(standard_metadata.egress_spec,port);

}
table do_fwd_tbl{
    //reads {
      //  standard_metadata.ingress:exact;
    //}
    actions {
        do_fwd;
    }
}

control ingress{
    apply(do_fwd_tbl);
}
control egress {
    apply(add_vlan_tbl);
}

