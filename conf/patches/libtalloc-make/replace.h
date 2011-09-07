
#ifndef __REPLACE_H__
#define __REPLACE_H__

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

typedef char bool;
#define true 1
#define false 0

#define _PUBLIC_
#define HAVE_VA_COPY

#define MIN(a,b) ((a)<(b)?(a):(b))
#define PTR_DIFF(p1,p2) ((((const char *)(p1)) - (const char *)(p2)))

#endif
