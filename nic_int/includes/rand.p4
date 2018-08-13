
counter dummy_counter {
    type : packets;
    
    instance_count : 1;
}


/*********************************************
    Generating random number
**********************************************/
#define RANDOM_NUM_BIT_WIDTH 32
field_list l3_rand_hash_fields {
    rand_meta.random_num;
}

field_list_calculation rand_hash {
    input {
        l3_rand_hash_fields;
    }
    algorithm : crc32;
    output_width : RANDOM_NUM_BIT_WIDTH;
}
//count for droped packet
action _drop() {
    count(dummy_counter,0);
    drop();
}
//generate randon num
primitive_action gen_random_num();
action set_rand_select(base, cnt, ratio) {
//
    gen_random_num();
    //
    //sampling_random_num = base + rand_hash % cnt
    modify_field_with_hash_based_offset(rand_meta.sampling_random_num, base,
                                        rand_hash, cnt);
    modify_field(rand_meta.sampling_ratio, ratio);
   
}

table set_rand_select {
    actions {
        set_rand_select;
    
    }

}


