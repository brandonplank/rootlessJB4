//
//  kernel_base.c
//  rootlessJB4
//
//  Created by Brandon Plank on 4/24/20.
//  Copyright © 2020 Brandon Plank. All rights reserved.
//

#include <CommonCrypto/CommonCrypto.h>
#include <CoreFoundation/CoreFoundation.h>
#include <mach-o/loader.h>
#include <mach/mach.h>

#define PROC_TASK_OFF (0x10)
#define OS_STRING_STRING_OFF (0x10)
#define OS_DICTIONARY_COUNT_OFF (0x14)
#define IO_DT_NVRAM_OF_DICT_OFF (0xC0)
#define IPC_PORT_IP_KOBJECT_OFF (0x68)
#define OS_DICTIONARY_DICT_ENTRY_OFF (0x20)
#ifdef __arm64e__
#    define CPU_DATA_RTCLOCK_DATAP_OFF (0x190)
#else
#    define CPU_DATA_RTCLOCK_DATAP_OFF (0x198)
#endif
#define VM_KERNEL_LINK_ADDRESS (0xFFFFFFF007004000ULL)
#define APPLE_MOBILE_AP_NONCE_GENERATE_NONCE_SEL (0xC8)
#define kCFCoreFoundationVersionNumber_iOS_13_0_b2 (1656)
#define kCFCoreFoundationVersionNumber_iOS_13_0_b1 (1652.20)
#define APPLE_MOBILE_AP_NONCE_BOOT_NONCE_OS_SYMBOL_OFF (0xC0)
#define PROC_P_PID_OFF (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0_b2 ? 0x68 : 0x60)
#define TASK_ITK_REGISTERED_OFF (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0_b1 ? 0x308 : 0x2E8)

#define KADDR_FMT "0x%" PRIX64
#define VM_KERN_MEMORY_CPU (9)
#define RD(a) extract32(a, 0, 5)
#define RN(a) extract32(a, 5, 5)
#define IS_RET(a) ((a) == 0xD65F03C0U)
#define ADRP_ADDR(a) ((a) & ~0xFFFULL)
#define ADRP_IMM(a) (ADR_IMM(a) << 12U)
#define IO_OBJECT_NULL ((io_object_t)0)
#define ADD_X_IMM(a) extract32(a, 10, 12)
#define LDR_X_IMM(a) (sextract64(a, 5, 19) << 2U)
#define IS_ADR(a) (((a) & 0x9F000000U) == 0x10000000U)
#define IS_ADRP(a) (((a) & 0x9F000000U) == 0x90000000U)
#define IS_ADD_X(a) (((a) & 0xFFC00000U) == 0x91000000U)
#define IS_LDR_X(a) (((a) & 0xFF000000U) == 0x58000000U)
#define LDR_X_UNSIGNED_IMM(a) (extract32(a, 10, 12) << 3U)
#define kBootNoncePropertyKey "com.apple.System.boot-nonce"
#define kIONVRAMDeletePropertyKey "IONVRAM-DELETE-PROPERTY"
#define IS_LDR_X_UNSIGNED_IMM(a) (((a) & 0xFFC00000U) == 0xF9400000U)
#define ADR_IMM(a) ((sextract64(a, 5, 19) << 2U) | extract32(a, 29, 2))
#define kIONVRAMForceSyncNowPropertyKey "IONVRAM-FORCESYNCNOW-PROPERTY"

#ifndef SEG_TEXT_EXEC
#    define SEG_TEXT_EXEC "__TEXT_EXEC"
#endif

#ifndef SECT_CSTRING
#    define SECT_CSTRING "__cstring"
#endif

#ifndef MIN
#    define MIN(a, b) ((a) < (b) ? (a) : (b))
#endif

typedef uint64_t kaddr_t;
typedef mach_port_t io_object_t;
typedef io_object_t io_service_t;
typedef io_object_t io_connect_t;
typedef io_object_t io_registry_entry_t;

typedef struct {
    struct section_64 s64;
    char *data;
} sec_64_t;

typedef struct {
    sec_64_t sec_text, sec_cstring;
} pfinder_t;

typedef struct {
    kaddr_t key, val;
} dict_entry_t;

kern_return_t
IOServiceClose(io_connect_t);

kern_return_t
IOObjectRelease(io_object_t);

CFMutableDictionaryRef
IOServiceMatching(const char *);

io_service_t
IOServiceGetMatchingService(mach_port_t, CFDictionaryRef);

kern_return_t
IOServiceOpen(io_service_t, task_port_t, uint32_t, io_connect_t *);

kern_return_t
IORegistryEntrySetCFProperty(io_registry_entry_t, CFStringRef, CFTypeRef);

kern_return_t
mach_vm_write(vm_map_t, mach_vm_address_t, vm_offset_t, mach_msg_type_number_t);

kern_return_t
IOConnectCallStructMethod(io_connect_t, uint32_t, const void *, size_t, void *, size_t *);

kern_return_t
mach_vm_read_overwrite(vm_map_t, mach_vm_address_t, mach_vm_size_t, mach_vm_address_t, mach_vm_size_t *);

kern_return_t
mach_vm_machine_attribute(vm_map_t, mach_vm_address_t, mach_vm_size_t, vm_machine_attribute_t, vm_machine_attribute_val_t *);

kern_return_t
mach_vm_region(vm_map_t, mach_vm_address_t *, mach_vm_size_t *, vm_region_flavor_t, vm_region_info_t, mach_msg_type_number_t *, mach_port_t *);

extern const mach_port_t kIOMasterPortDefault;


static kern_return_t
kread_buf(kaddr_t addr, void *buf, mach_vm_size_t sz, mach_port_t tfp0) {
    mach_vm_address_t p = (mach_vm_address_t)buf;
    mach_vm_size_t read_sz, out_sz = 0;

    while(sz != 0) {
        read_sz = MIN(sz, vm_kernel_page_size - (addr & vm_kernel_page_mask));
        if(mach_vm_read_overwrite(tfp0, addr, read_sz, p, &out_sz) != KERN_SUCCESS || out_sz != read_sz) {
            return KERN_FAILURE;
        }
        p += read_sz;
        sz -= read_sz;
        addr += read_sz;
    }
    return KERN_SUCCESS;
}



static kern_return_t
kread_addr(kaddr_t addr, kaddr_t *val, mach_port_t tfp0) {
    return kread_buf(addr, val, sizeof(*val), tfp0);
}


kaddr_t get_kbase(kaddr_t *kslide, mach_port_t tfp0) {
    mach_msg_type_number_t cnt = TASK_DYLD_INFO_COUNT;
    vm_region_extended_info_data_t extended_info;
    task_dyld_info_data_t dyld_info;
    kaddr_t addr, rtclock_datap;
    struct mach_header_64 mh64;
    mach_port_t obj_nm;
    mach_vm_size_t sz;

    if(task_info(tfp0, TASK_DYLD_INFO, (task_info_t)&dyld_info, &cnt) == KERN_SUCCESS && dyld_info.all_image_info_size != 0) {
        *kslide = dyld_info.all_image_info_size;
        return VM_KERNEL_LINK_ADDRESS + *kslide;
    }
    cnt = VM_REGION_EXTENDED_INFO_COUNT;
    for(addr = 0; mach_vm_region(tfp0, &addr, &sz, VM_REGION_EXTENDED_INFO, (vm_region_info_t)&extended_info, &cnt, &obj_nm) == KERN_SUCCESS; addr += sz) {
        mach_port_deallocate(mach_task_self(), obj_nm);
        if(extended_info.user_tag == VM_KERN_MEMORY_CPU && extended_info.protection == VM_PROT_DEFAULT) {
            if(kread_addr(addr + CPU_DATA_RTCLOCK_DATAP_OFF, &rtclock_datap, tfp0) != KERN_SUCCESS) {
                break;
            }
            printf("rtclock_datap: " KADDR_FMT "\n", rtclock_datap);
            rtclock_datap = trunc_page_kernel(rtclock_datap);
            do {
                if(rtclock_datap <= VM_KERNEL_LINK_ADDRESS) {
                    return 0;
                }
                rtclock_datap -= vm_kernel_page_size;
                if(kread_buf(rtclock_datap, &mh64, sizeof(mh64), tfp0) != KERN_SUCCESS) {
                    return 0;
                }
            } while(mh64.magic != MH_MAGIC_64 || mh64.cputype != CPU_TYPE_ARM64 || mh64.filetype != MH_EXECUTE);
            *kslide = rtclock_datap - VM_KERNEL_LINK_ADDRESS;
            return rtclock_datap;
        }
    }
    return 0;
}
