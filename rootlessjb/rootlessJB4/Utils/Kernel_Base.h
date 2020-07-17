//
//  kernel_base.h
//  rootlessJB4
//
//  Created by Brandon Plank on 4/24/20.
//  Copyright © 2020 Brandon Plank. All rights reserved.
//

#ifndef kernel_base_h
#define kernel_base_h

#include <stdio.h>

typedef uint64_t kaddr_t;

kaddr_t get_kbase(kaddr_t *kslide, mach_port_t tfp0);
#endif /* kernel_base_h */
