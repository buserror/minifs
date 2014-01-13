/*
 * SPI testing utility (using spidev driver)
 * 
 * Revised for multiple transaction, half duplex SPI etc.
 *
 * Copyright (c) 2007  MontaVista Software, Inc.
 * Copyright (c) 2007  Anton Vorontsov <avorontsov@ru.mvista.com>
 * Copyright (c) 2012  Michel Pollet <michel@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License.
 *
 * Cross-compile with cross-gcc -I/path/to/cross-kernel/include
 */

#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <fcntl.h>
#include <string.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <linux/spi/spidev.h>
#include <ctype.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

int debug = 0;
static void pabort(const char *s)
{
	perror(s);
	if (!debug)
		abort();
}

static const char *device = "/dev/spidev1.1";
static uint8_t mode;
static uint8_t bits = 8;
static uint32_t speed = 500000;
static uint16_t delay;
int verbose = 0;

uint8_t	txbuffer[1024];

struct spi_ioc_transfer queue[8];
int queuelen = 0;


static void
transfer(
		int fd)
{
	int ret;

	if (verbose)
		printf("Will ");

	for (int i = 0; i < queuelen; i++) {
		queue[i].delay_usecs = delay;
		queue[i].speed_hz = speed;
		queue[i].bits_per_word = bits;
		if (verbose)
			printf("%s%s %d", i > 0 ? ", " : "",
					queue[i].rx_buf ? "read" : "write",
							queue[i].len);
	}
	if (verbose)
		printf(" bytes\n");
	ret = ioctl(fd, SPI_IOC_MESSAGE(queuelen), queue);
	if (ret < 1)
		pabort("can't send spi message");

	for (int i = 0; i < queuelen; i++) {
		printf("%s(%d) ", queue[i].rx_buf ? "read" : "write", queue[i].len);
		uint8_t *b = (uint8_t *)(queue[i].rx_buf ? queue[i].rx_buf : queue[i].tx_buf);
		for (int bi = 0; bi < queue[i].len; bi++) {
			if (bi && !(bi % 32))
				puts("");
			printf("%02X ", b[bi]);
		}
	}
	puts("");
}

static void print_usage(const char *prog)
{
	printf("Usage: %s [-DsbdlHOLC3]\n", prog);
	puts("  -D --device   device to use (default /dev/spidev1.1)\n"
	     "  -s --speed    max speed (Hz)\n"
	     "  -d --delay    delay (usec)\n"
		 "  -r --rx	      Number of bytes to read (0)\n"
	     "  -b --bpw      bits per word \n"
	     "  -l --loop     loopback\n"
	     "  -H --cpha     clock phase\n"
	     "  -O --cpol     clock polarity\n"
	     "  -L --lsb      least significant bit first\n"
	     "  -C --cs-high  chip select active high\n"
	     "  -3 --3wire    SI/SO signals shared\n"
		 "  -N --no-cs    Don't assert CS\n"
		 "  -R --ready    Ready mode\n"
		 "  -v --verbose  Verbose output\n"
			);
	exit(1);
}

static void
parse_opts(int argc, char *argv[])
{
	static const struct option lopts[] = {
		{ "device",  1, 0, 'D' },
		{ "speed",   1, 0, 's' },
		{ "delay",   1, 0, 'd' },
		{ "bpw",     1, 0, 'b' },
		{ "rx",      1, 0, 'r' },
		{ "loop",    0, 0, 'l' },
		{ "cpha",    0, 0, 'H' },
		{ "cpol",    0, 0, 'O' },
		{ "lsb",     0, 0, 'L' },
		{ "cs-high", 0, 0, 'C' },
		{ "3wire",   0, 0, '3' },
		{ "no-cs",   0, 0, 'N' },
		{ "ready",   0, 0, 'R' },
		{ "verbose", 0, 0, 'v' },
		{ NULL, 0, 0, 0 },
	};
	while (1) {
		int c;

		c = getopt_long(argc, argv, "D:s:d:b:r:lHOLC3NRv", lopts, NULL);

		if (c == -1)
			break;

		switch (c) {
			case 'D':
				device = optarg;
				break;
			case 's':
				speed = atoi(optarg);
				break;
			case 'd':
				delay = atoi(optarg);
				break;
			case 'b':
				bits = atoi(optarg);
				break;
			case 'l':
				mode |= SPI_LOOP;
				break;
			case 'H':
				mode |= SPI_CPHA;
				break;
			case 'O':
				mode |= SPI_CPOL;
				break;
			case 'L':
				mode |= SPI_LSB_FIRST;
				break;
			case 'C':
				mode |= SPI_CS_HIGH;
				break;
			case '3':
				mode |= SPI_3WIRE;
				break;
			case 'N':
				mode |= SPI_NO_CS;
				break;
			case 'R':
				mode |= SPI_READY;
				break;
			case 'v':
				verbose++;
				break;
			case 'r': {
				int len = atoi(optarg);
				uint8_t *b = malloc(len + 1);
				queue[queuelen].rx_buf = (__u64)b;
				memset(b, 0, len);
				queue[queuelen].len = len;
				queuelen++;
			}	break;
			default:
				print_usage(argv[0]);
				break;
		}
	}
	while (optind < argc) {
	//    printf("%s ", argv[optind]);

	    char * src = argv[optind];
	    int srcl = strlen(src);
	    const char * h = "0123456789abcdef";
	    int len = 0;
	    uint8_t buf[4096];
	    while (srcl >= 2) {
	    	if (!isxdigit(src[0]) || !isxdigit(src[1])) {
	    		pabort("Invalid hex format\n");
	    	}
	    	uint8_t b = ((index(h, tolower(src[0])) - h) << 4) | (index(h, tolower(src[1])) - h);
	    	buf[len++] = b;
	    	src += 2;
	    	srcl -= 2;
	    }
	    if (len) {
	    	uint8_t *b = malloc(len + 1);
			queue[queuelen].tx_buf = (__u64)b;
			memcpy(b, buf, len);
			queue[queuelen].len = len;
			queuelen++;
	    }
	    optind++;
	}
}

int
main(
		int argc,
		char *argv[])
{
	int ret = 0;
	int fd;

	memset(queue, 0, sizeof(queue));
	debug = getenv("DEBUG") ? atoi(getenv("DEBUG")) : 0;

	parse_opts(argc, argv);

	fd = open(device, O_RDWR);
	if (fd < 0)
		pabort("can't open device");

	/*
	 * spi mode
	 */
	ret = ioctl(fd, SPI_IOC_WR_MODE, &mode);
	if (ret == -1)
		pabort("can't set spi mode");

	ret = ioctl(fd, SPI_IOC_RD_MODE, &mode);
	if (ret == -1)
		pabort("can't get spi mode");

	/*
	 * bits per word
	 */
	ret = ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &bits);
	if (ret == -1)
		pabort("can't set bits per word");

	ret = ioctl(fd, SPI_IOC_RD_BITS_PER_WORD, &bits);
	if (ret == -1)
		pabort("can't get bits per word");

	/*
	 * max speed hz
	 */
	ret = ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed);
	if (ret == -1)
		pabort("can't set max speed hz");

	ret = ioctl(fd, SPI_IOC_RD_MAX_SPEED_HZ, &speed);
	if (ret == -1)
		pabort("can't get max speed hz");

	if (verbose) {
		printf("spi mode: %d\n", mode);
		printf("bits per word: %d\n", bits);
		printf("max speed: %d Hz (%d KHz)\n", speed, speed/1000);
	}
	transfer(fd);

	close(fd);

	return ret;
}
