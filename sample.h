/******************************************************************************
* File:             sample.h
*
* Author:           Hyunwoo Oh 
* Created:          04/27/19 
* Description:      Sample header file
*****************************************************************************/

#ifndef SAMPLE_H
#define SAMPLE_H

#include <stdio.h>
#include <stdint.h>

// sample struct
struct str {
    int32_t a;
    float b;
    uint32_t *c;
};
/* sample typedef struct */
typedef struct str2 {
    int32_t a;
    float b;
    uint32_t *c;
} structure;
extern int a; // sample integer
void sample(int a, int b, int c); /* sample function */


#endif
