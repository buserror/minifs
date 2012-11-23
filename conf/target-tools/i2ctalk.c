/*
	i2ctalk.c

	Copyright 2008, 2009 Michel Pollet <buserror@gmail.com>

 	This file is part of simavr.

	simavr is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	simavr is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with simavr.  If not, see <http://www.gnu.org/licenses/>.
 */
#include <linux/i2c.h>
#include <linux/i2c-dev.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <fcntl.h>
#include <libgen.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <math.h>

int bus = 0;
int i2c = -1;
int address = 0;
struct i2c_msg msg[16];
int msg_count = 0;
uint8_t buffer[128];
uint8_t * write_ptr = buffer;
const char * display_mode[16] = {0};
const char * self;

static void reopen_bus()
{
	if (i2c != -1)
		close(i2c);
	i2c = -1;
//	printf("Opening bus %d\n", bus);
	char path[32];
	sprintf(path, "/dev/i2c-%d", bus);
	i2c = open(path, O_RDWR);
	if (i2c == -1) {
		perror(path);
		exit(1);
	}
//	ioctl(i2c, I2C_TIMEOUT, 0); /* set the timeout    */
//	ioctl(i2c, I2C_RETRIES, 1); /* set the retries    */
}

int process_silent = 0;

static int process()
{
	if (!msg_count)
		return 0;
	if (i2c == -1)
		reopen_bus();

	struct i2c_rdwr_ioctl_data rdwr = {msg, msg_count};

	if (ioctl(i2c, I2C_RDWR, &rdwr) < 0) {
		if (!process_silent)
			perror("I2C_RDWR");
		return -1;
	}
//	printf("Done\n");
	usleep(10000);
	return msg_count;
}

static void display()
{
	if (!msg_count)
		return;
	// now decode whatever was read
	for (int di = 0; di < msg_count; di++) {
		const char * src = display_mode[di];
		if (!src)
			continue;
		printf("%02x: ", msg[di].addr);

		uint8_t * buf = msg[di].buf;

		int count = 0;
		while (*src) {
			switch (*src) {
				case '0' ... '9' :
					count = (count*10) + (*src++ - '0');
					break;
				case 'b':
					count = count ? count : 1;
					for (int bi = 0; bi < count; bi++)
						printf("%02x", *buf++);
					printf(" ");
					count = 0;
					src++;
					break;
				case 's':
					count = count ? count : 1;
					for (int bi = 0; bi < count; bi++, buf += 2) {
						short s = (buf[0] << 8) | (buf[1]);
						printf("%02x%02x %6d ", buf[0],  buf[1], s);
					}
					count = 0;
					src++;
					break;
				case 'l':
					count = count ? count : 1;
					for (int bi = 0; bi < count; bi++, buf += 4)
						printf("%02x%02x%02x%02x %8d ", buf[0], buf[1],buf[2],buf[3],
								(int)(buf[0] << 24) | (buf[1] << 16) | (buf[2] << 8) | (buf[3]));
					count = 0;
					src++;
					break;
				case 't': {
					short s = (buf[0] << 8) | (buf[1]);
					printf("%02x%02x %6d %.2f", buf[0],  buf[1], s, (float)s / 256.0f);
					src++;
				}	break;
				case 'g': {
					uint16_t y = buf[0] | ((buf[3] & ~3) << 6);
					uint16_t p = buf[1] | ((buf[4] & ~3) << 6);
					uint16_t r = buf[2] | ((buf[5] & ~3) << 6);
					printf(" %c Yaw %6d %c Pitch %6d %c Roll %6d ",
							buf[3] & 2 ? '>' : ' ', y,
							buf[3] & 1 ? '>' : ' ', p,
							buf[4] & 2 ? '>' : ' ', r);
					src++;
				}	break;
				case 'c': {
					int16_t x = (buf[2] | (buf[1] << 8)) - 2048;
					int16_t y = (buf[4] | (buf[3] << 8)) - 2048;
					float deg = 0.0f;
					printf("Compass x %5d y %5d ", x, y);
					if (y) {
						float xy = (float)x / (float)y;
						if (y > 0)
							deg = 90 - (atan(xy) * 180.0f / 3.14159f);
						else
							deg = 270 - (atan(xy) * 180.0f / 3.14159f);
					} else {
						if (x < 0)
							deg = 180.0f;
					}
					printf("compass = %.2f ", deg);
					src++;
				}	break;
				case 'a': {
					int16_t x = buf[1] | (buf[0] << 8);
					int16_t y = buf[3] | (buf[2] << 8);
					int16_t z = buf[5] | (buf[4] << 8);

					float xf = (float)x / 1024.0f;
					float yf = (float)y / 1024.0f;
					float zf = (float)z / 1024.0f;

					float r = sqrtf(powf(xf, 2) + powf(yf, 2) + powf(zf, 2));

					float ax = acosf(xf / r) * (180.0f / 3.1415926535f);
					float ay = acosf(yf / r) * (180.0f / 3.1415926535f);
					float az = acosf(zf / r) * (180.0f / 3.1415926535f);
					printf("(%d %d %d) r=%.4f Accel x %3.4f y %3.4f z %3.4f ", x,y,z, r, ax, ay, az);
					src++;
				}	break;
				case ' ':
					break;
			}
		}
		printf("\n");
	}
	msg_count = 0;
}

int main(int argc, const char * argv[])
{
	const char * hex = "0123456789abcdef";

	self = basename((char*)argv[0]);

	for (int ai = 1; ai < argc; ai++) {
		const char * src = argv[ai];
		display_mode[ai] = NULL;

		if (!strcmp(argv[ai], "--loop")) {
			bus = 4;
			msg[0].addr = 0x55;
			msg_count = 1;

			while (1) {
				process();
				sleep(1);
			}
		}
		while (*src) {
			char c = *src++;
			switch (c) {
				case '=': {
					if (process() > 0)
						display();
					bus = 0;
					while (isdigit(*src))
						bus = (bus * 10) + (*src++ - '0');
				}	break;
				case 'p': {
					process_silent = 1;
					for (int i = 0; i < 255; i++) {
						if (!(i % 16)) printf("%02x: ", i);
						msg[0].addr = i;
						msg_count = 1;
						if (process() >= 0)
							printf("%02x ", i);
						else printf(" - ");
						if ((i % 16)==15) printf("\n");
					}
				}	break;
				case '@': {
					if (process() > 0)
						display();

					address = 0;
					while (isxdigit(*src))
						address = (address << 4) | (int)(strchr(hex, tolower(*src++)) - hex);
				//	printf("Set address to 0x%2x\n", address);
				}	break;
				case 'w': {
					msg[msg_count].addr = address;
					msg[msg_count].flags = 0;
					msg[msg_count].len = 0;
					msg[msg_count].buf = write_ptr;
					while (isxdigit(src[0]) && isxdigit(src[1])) {
						uint8_t byte = ((strchr(hex, tolower(src[0])) - hex) << 4) |
								(int)(strchr(hex, tolower(src[1])) - hex);
						src += 2;
						*write_ptr++ = byte;
						msg[msg_count].len++;
					}
					if (msg[msg_count].len) {
					//	printf("Write %d bytes : ", msg[msg_count].len);
					//	for (int i = 0; i < msg[msg_count].len; i++)
					//		printf("%02x", msg[msg_count].buf[i]);
					//	printf("\n");
						msg_count++;
					} else {
						fprintf(stderr, "%s: Warning '%s' won't write anything\n", self, argv[ai]);
					}
				}	break;
				case 'r': {
					msg[msg_count].addr = address;
					msg[msg_count].flags = I2C_M_RD;
					msg[msg_count].len = 0;
					msg[msg_count].buf = write_ptr;
					display_mode[msg_count] = src; // keep it around for display

					int count = 0;
					while (*src) {
						switch (*src) {
							case '0' ... '9' :
								count = (count*10) + (*src++ - '0');
								break;
							case 'b':
								count = count ? count : 1;
								msg[msg_count].len += count;
								write_ptr += count;
								count = 0;
								src++;
								break;
							case 's':
								count = count ? count * 2 : 2;
								msg[msg_count].len += count;
								write_ptr += count;
								count = 0;
								src++;
								break;
							case 't':	// temperature
								count = 2;
								msg[msg_count].len += count;
								write_ptr += count;
								count = 0;
								src++;
								break;
							case 'l':
								count = count ? count * 4 : 4;
								msg[msg_count].len += count;
								write_ptr += count;
								count = 0;
								src++;
								break;
							case 'g':		// gyro from MotionPlus
								count = 6;
								msg[msg_count].len += count;
								write_ptr += count;
								count = 0;
								src++;
								break;
							case 'c':		// compass module
								count = 5;
								msg[msg_count].len += count;
								write_ptr += count;
								count = 0;
								src++;
								break;
							case 'a':		// accelerometer
								count = 6;
								msg[msg_count].len += count;
								write_ptr += count;
								count = 0;
								src++;
								break;
							case ' ':
								break;
							default:
								printf("Unknown format '%c' for reading\n", c);
								exit(1);
						}
					}
					if (msg[msg_count].len) {
					//	printf("Reading %d bytes\n", msg[msg_count].len);
						msg_count++;
					} else {
						display_mode[msg_count] = NULL;
						fprintf(stderr, "%s: Warning '%s' won't read anything\n", self, argv[ai]);
					}
				}	break;
				case ' ':
					break;
				default:
					fprintf(stderr, "%s: ERROR Unknown command character '%c'\n", self, c);
					exit(1);
			}
		}
	}
	if (process() > 0)
		display();
}
