//for 204


#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/rand.p4"

primitive_action do_read_ingress_current_time();
primitive_action do_read_egress_current_time();
primitive_action do_read_drop_counter();
/*
 * not INT case, we just drop and count
 */
action set_ingress_global_tstamp() {
    do_read_ingress_current_time();

}
action set_egress_global_tstamp() {
    do_read_egress_current_time();
}
action set_drop_counter() {
    do_read_drop_counter();
}
counter drop_counter {
    type : packets;
    instance_count : 1;
}

action do_drop() {
    count(drop_counter, 0);
    drop();
}



action do_forward(espec) {
    modify_field(standard_metadata.egress_spec, espec);
    
}


table tbl_forward {
    reads {
        standard_metadata.ingress_port : exact;
        ipv4.dstAddr                   : ternary;
    }
    actions {
        do_forward;
        do_drop;
    }
}

table tbl_read_ingress_current_time {
    actions {
        set_ingress_global_tstamp;
    }
}
table tbl_read_egress_current_time {
    actions {

        set_egress_global_tstamp;
    }

}
table tbl_read_drop_counter {
    actions {
        set_drop_counter;
    }
}

/*
 * Egress INT processing
 */
action int_set_header_drop_counter() {
    add_header(int_drop_counter_header);
    
    modify_field(int_drop_counter_header.low, intrinsic_metadata.drop_counter_low);
    modify_field(int_drop_counter_header.high, intrinsic_metadata.drop_counter_high);

}
/* Instr Bit 0 */
action int_set_header_switch_id() { //switch_id
    add_header(int_switch_id_header);
    modify_field(int_switch_id_header.switch_id, SWITCH_ID);
//    add_to_field(vxlan_gpe_int_header.len, 1);
}

/* Instr Bit 1 */
action int_set_header_ingress_port_id() { //ingress_port_id

    add_header(int_ingress_port_id_header);
    modify_field(int_ingress_port_id_header.ingress_port_id, standard_metadata.ingress_port);
//    add_to_field(vxlan_gpe_int_header.len, 1);

}



/* Instr Bit 2 */
action int_set_header_ingress_tstamp() { //ingress_tstamp
    add_header(int_ingress_tstamp_header);
    modify_field(int_ingress_tstamp_header.ingress_tstamp,
                 intrinsic_metadata.ingress_global_tstamp);
//    add_to_field(vxlan_gpe_int_header.len, 1);
}
/* Instr Bit 3 */
action int_set_header_egress_port_id() { //egress_port_id
    add_header(int_egress_port_id_header);
    modify_field(int_egress_port_id_header.egress_port_id,
                    standard_metadata.egress_port);
//   add_to_field(vxlan_gpe_int_header.len, 1);
}

/* Instr Bit 4 */
action int_set_header_egress_tstamp() { //egress_tstamp
    add_header(int_egress_tstamp_header);
    modify_field(int_egress_tstamp_header.egress_tstamp,
                 intrinsic_metadata.egress_global_tstamp);
//    add_to_field(vxlan_gpe_int_header.len,1);

}


/* BOS bit - set for the bottom most header added by INT src device */
action int_set_bos_switch_id() {
    modify_field(int_switch_id_header.bos, 1);
}



//tables
table int_instance_drop_counter {
    actions {
        int_set_header_drop_counter;
    }
}
table int_instance_switch_id {
    actions {
        int_set_header_switch_id;
    }
}
table int_instance_ingress_port_id {
    actions {
        int_set_header_ingress_port_id;
    }
}
table int_instance_ingress_tstamp {
    actions {
        int_set_header_ingress_tstamp;
    }
}
table int_instance_egress_port_id {
    actions {
        int_set_header_egress_port_id;
    }
}
table int_instance_egress_tstamp {
    actions {
        int_set_header_egress_tstamp;
    }
}
table int_bos_switch_id {
    actions {
        int_set_bos_switch_id;
    }
}


control insert_int_stack {
#ifdef CNT
    apply(int_instance_drop_counter);
#endif
    apply(int_instance_ingress_port_id);
    apply(int_instance_ingress_tstamp);
    apply(int_instance_egress_port_id);
    apply(int_instance_egress_tstamp);
    apply(int_instance_switch_id);
}


/*
        |   switchId  |
        |ingressportId|
        |ingressstamp |
        |egressportId |
        |egressstamp  | <-----set bos

*/

action int_src(max_hop_cnt) {
    modify_field(ipv4.protocol,0xfe);
    add_header(int_header);

    modify_field(int_header.max_hop_cnt, max_hop_cnt);
    modify_field(int_header.total_hop_cnt, 0);
  
    
}
table int_insert {
    actions {
        int_src;
    }
}

action int_update_hop_cnt() {
    add_to_field(int_header.total_hop_cnt, 1);
}

table int_header_update {
    // This table is applied only if int_insert table is a hit, which
    // computes insert_cnt
    // E bit is set if insert_cnt == 0
    // Else total_hop_cnt is incremented by one

    actions {
        int_update_hop_cnt;
        
    }
    size : 1;
}
field_list copy_to_cpu_fields {
    standard_metadata;

}
action mirror(mirror_port) {
    modify_field(standard_metadata.egress_spec,mirror_port);
    clone_egress_pkt_to_egress(mirror_port, copy_to_cpu_fields);
    
}
table tbl_mirror {
    actions {
        mirror;
    }
}
action remove_int_header() {
    remove_header(int_header);
    modify_field(ipv4.protocol, 0x06);
    remove_header(int_value[0]);
    remove_header(int_value[1]);
    remove_header(int_value[2]);
    remove_header(int_value[3]);
    remove_header(int_value[4]);
    pop(int_value, 10);

}
table tbl_remove_int_header {
    actions {
        remove_int_header;
    }
}
control ingress {
        
    apply(set_rand_select);
    if (rand_meta.sampling_random_num < rand_meta.sampling_ratio) {
        apply(tbl_read_ingress_current_time);
        
    } 

    //apply(tbl_read_ingress_current_time);  
    apply(tbl_forward); 
   
    
}
control source_node {
    if (rand_meta.sampling_random_num < rand_meta.sampling_ratio) {
#ifdef CNT
        apply( tbl_read_drop_counter);
#endif
        apply(tbl_read_egress_current_time);            
        apply(int_insert);       
        apply(int_bos_switch_id);       
        insert_int_stack(); 
        apply(int_header_update);
        
    }

}
control intermediate_node {
    if (valid (int_header)) {
#ifdef CNT
        apply(tbl_read_drop_counter);
#endif
        apply(tbl_read_egress_current_time); 
        insert_int_stack(); 
        apply(int_header_update);      
    
    }

}
control egress  { 
#ifdef SRC
    if (standard_metadata.instance_type == 0) {// 0 ==normal
        source_node();  
    }     
#else //SRC
    if (standard_metadata.instance_type == 0) {// 0 == normal
        intermediate_node();
    }    
#endif//SRC

#ifdef SINK
    if (valid (int_header)) {        
        if (standard_metadata.instance_type == 0) {
            apply(tbl_mirror);
            //apply(tbl_remove_int_header);
        }
        
    
    }
#endif    


}
