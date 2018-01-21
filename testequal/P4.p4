header_type ethernet_t {
    fields{
        dstAddr : 48;
        srcAddr : 48;
        ethertype : 16;   
    }

}

header ethernet_t ethernet;

parser start {
    return parser_ethernet;
}
parser parser_ethernet {
    extract(ethernet);
    return ingress;

}


action add_vlan(){
    modify_field(ethernet.ethertype,2);

}
action do_fwd(){
    modify_field(standard_metadata.egress_spec,);

}
table do_fwd_tbl{
    actions {
        do_fwd;
    }
}

control ingress{

    if(ethernet.ethertype == 1) {
        apply(do_fwd_tbl);
        apply(add_vlan_tbl);
    }   

}
control egress {


}

