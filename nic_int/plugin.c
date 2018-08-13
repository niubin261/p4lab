#include <stdint.h>
#include <nfp/me.h>
#include <nfp/mem_atomic.h>
#include "pif_common.h"
#include "pif_plugin.h"
#include "pif_registers.h"
#include <stdlib.h>

#include <pif_headers.h>
//#include <nfptypes.h>
#include <nfp.h>

#include <pif_plugin_metadata.h>

static uint8_t first = 1;
int pif_plugin_do_read_ingress_current_time(EXTRACTED_HEADERS_T *headers,
                                            MATCH_DATA_T *match_data) {
    uint64_t ctime;
    ctime = me_tsc_read();
    
    pif_plugin_meta_set__intrinsic_metadata__ingress_global_tstamp(headers,ctime & 0x7fffffff);
    return PIF_PLUGIN_RETURN_FORWARD;

}

int pif_plugin_do_read_egress_current_time(EXTRACTED_HEADERS_T *headers,
                                            MATCH_DATA_T *match_data) {
    uint64_t ctime;
    ctime = me_tsc_read();
    pif_plugin_meta_set__intrinsic_metadata__egress_global_tstamp(headers,ctime & 0x7fffffff);
    return PIF_PLUGIN_RETURN_FORWARD;                                           
                                            
}


int pif_plugin_gen_random_num(EXTRACTED_HEADERS_T *headers, MATCH_DATA_T *match_data) {
    __xrw uint32_t randval ;
    __xrw uint64_t time;
    time = me_tsc_read();
    if (first) {
        first = 0;
        //local_csr_write(local_csr_pseudo_random_number,(local_csr_read(local_csr_timestamp_low) & 0xffff) + 1); 
        srand(time & 0x7fffffff);     
    }
    
    randval = rand();   
    //randval = local_csr_read(local_csr_pseudo_random_number) & 0x7fffffff ;

    pif_plugin_meta_set__rand_meta__random_num(headers,randval);
    return PIF_PLUGIN_RETURN_FORWARD;

}
int pif_plugin_do_read_drop_counter(EXTRACTED_HEADERS_T *headers, MATCH_DATA_T *match_data) {
    __xread uint32_t drop_counter[2];
    mem_read_atomic(drop_counter, ((__emem uint64_t *)pif_register_drop_counter), sizeof(drop_counter));
    pif_plugin_meta_set__intrinsic_metadata__drop_counter_low(headers, drop_counter[0]);
    pif_plugin_meta_set__intrinsic_metadata__drop_counter_high(headers, drop_counter[1]);
    return PIF_PLUGIN_RETURN_FORWARD;                                           
                                       


}
