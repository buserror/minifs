#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdint.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <unistd.h>
#include <string.h>

long long unsigned base = 0;
long long unsigned value = 0;
int set = 0, has_base = 0, has_value = 0;
int size = 0; // int
const char * device = "/dev/mem";

static void doarg(const char * arg)
{
	while (*arg == ' ')
		arg++;
	if (isxdigit(arg[0])) {
		char * eq = strchr(arg, '='); 
		if (eq) {
			set++;
			*eq++ = 0;
			doarg(arg);
			doarg(eq); 
		} else {
			if (sscanf(arg, "0x%llx", &value) ||
					sscanf(arg, "%llx", &value)) {
				printf("base (%s) = %llx\n", arg, value);
				if (!has_base) {
					base = value;
					value = 0;
					has_base++;
				} else
					has_value = 1;
			}
		}
	} else if (arg[0] == '-' && isdigit(arg[1]))
		sscanf(arg + 1, "%d", &size);
	else if (!strcmp(arg, "="))
		set++;
	else if (!strcmp(arg, "-b"))
		size = 1;
	else if (!strcmp(arg, "-s"))
		size = 2;
	else if (!strcmp(arg, "-l"))
		size = 4;
	else if (!strcmp(arg, "-ll"))
		size = 8;
}


int main(int argc, const char * argv[])
{	 
	int verbose = 0;
	
	for (int i = 1; i < argc; i++) {
		if ((!strcmp(argv[i], "-d") || !strcmp(argv[i], "--device")) &&
				i < argc - 1)
			device = argv[++i];
		else if (!strcmp(argv[i], "-v"))
			verbose++;
		else
			doarg(argv[i]);
	}
	if (verbose)
		printf("base=0x%llx value=0x%llx size=%d set=%d has_base=%d has_value=%d\n",
			base, value, size, set, has_base, has_value);
	if (!has_base || (has_base && set && !has_value)) {
		fprintf(stderr, "kmem [[-d|--device] /dev/xxx] [-v] [-<n>|-b|-s|-l|-ll] [0x]<base address> [= [0x]<value>]\n");
		exit(1);
	}
	
	const uint32_t pagesize = 4096;
	uint64_t map_start = base & ~(pagesize-1); 
	int offset = base - map_start;
	uint64_t map_end = (base + size + pagesize) & ~(pagesize-1);
	int map_size = map_end - map_start;

	if (verbose)
		printf("map_start=%llx offset=%d map_size=%d\n",
			map_start, offset, map_size);
	int fd = open(device, set ? O_RDWR : O_RDONLY);
	if (fd == -1) {
		perror(device);
		exit(1);
	}
	
	void *map_bb = mmap(NULL, map_size, 
			PROT_READ + (set ? PROT_WRITE : 0),
			MAP_SHARED,
			fd, map_start);
	if (map_bb == MAP_FAILED) {
		perror("mmap");
		exit(1);
	}
	void *bb = map_bb + offset;
	if (set) {
		switch (size) {
			case 0:
				*((int*)bb) = value;
				break;
			case 1:
				*((uint8_t*)bb) = value;
				break;
			case 2:
				*((uint16_t*)bb) = value;
				break;
			case 4:
				*((uint32_t*)bb) = value;
				break;
			case 8:
				*((long long unsigned*)bb) = value;
				break;
			default:
				fprintf(stderr, "invalid set size %d\n", size);
				exit(1);
		}
	} else {
		printf("%x: ", base));
		switch (size) {
			case 0:
				printf("%x", *((int*)bb));
				break;
			case 1:
				printf("%02x", *((uint8_t*)bb));
				break;
			case 2:
				printf("%04x", *((uint16_t*)bb));
				break;
			case 4:
				printf("%08x", *((uint32_t*)bb));
				break;
			case 8:
				printf("%llx", *((long long unsigned*)bb));
				break;
			default:
				for (int i = 0; i < size; i++)
					printf("%02x", ((uint8_t*)bb)[i]); 
				break;
		}
		printf("\n");
	}
}
