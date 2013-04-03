/*
 * fbtest.c
 * 
 * (c) Michel Pollet <buserror@gmail.com>
 * 
 * A log file in /tmp keeps trace of all the fixes and warnings, for
 * the brave who wants to go and fix the packages themselves
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 * 
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
 * Boston, MA  02110-1301, USA.
 */

#include <sys/ioctl.h>
#include <sys/mman.h>
#include <linux/fb.h>
#include <linux/kd.h>
#include <linux/vt.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <linux/fb.h>

int fbfd;
struct fb_var_screeninfo vinfo;
struct fb_fix_screeninfo finfo;
long int screensize;
uint8_t * fbp;

int
openfb()
{
	int vt = 2;
	int tty = open("/dev/tty0", O_WRONLY);
	perror("/dev/tty0");

#if 0
	if (ioctl(tty, VT_OPENQRY, &vt) < 0) {
		perror("ioctl VT_OPENQRY");
		return -1;
	}
	close(tty);

	char tty_name[32];
	sprintf(tty_name, "/dev/tty%d", vt);
	tty = open(tty_name, O_WRONLY|O_NDELAY);
	perror(tty_name);
#endif

	struct vt_stat vts;

	if (ioctl(tty, VT_GETSTATE, &vts) == -1) {
		perror("ioctl VT_GETSTATE");
	//	return -1;
	}
	if (ioctl(tty, VT_ACTIVATE, vt) == -1) {
		perror("ioctl VT_ACTIVATE");
	//	return -1;
	}
	if (ioctl(tty, VT_WAITACTIVE, vt) == -1) {
		perror("ioctl VT_WAITACTIVE");
	//	return -1;
	}
	if (ioctl(tty, KDSETMODE, KD_GRAPHICS) == -1) {
		perror("KDSETMODE, KD_GRAPHICS");
	//	return -1;
	}

	// open the frame buffer file for reading & writing
	fbfd = open ( "/dev/fb0", O_RDWR );
	if (!fbfd) {
		printf ("Error: can't open framebuffer device.\n");
		return -1;
	}
	printf ("The framebuffer device was opened successfully\n");

	if (ioctl (fbfd, FBIOGET_FSCREENINFO, &finfo)) {
		printf ("Error reading fixed information\n");
		close (fbfd);
		return -1;
	}

	if (ioctl (fbfd, FBIOGET_VSCREENINFO, &vinfo)) {
		printf ("Error reading variable information\n");
		close (fbfd);
		exit (3);
	}
	if (ioctl(fbfd,FBIOBLANK,0)) {
		perror ("FBIOBLANK");
		close (fbfd);
		return -1;
	}

	// print info about the buffer
	printf ("%dx%d, %dbpp\n", vinfo.xres, vinfo.yres, vinfo.bits_per_pixel);

	// calculates size
	screensize = vinfo.xres * vinfo.yres * vinfo.bits_per_pixel / 8;

	// map the device to memory
	fbp = (uint8_t *) mmap (0, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, fbfd, 0);

	if (fbp == (void*)-1) {
		printf ("Error: failed to map framebuffer device to memory\n");
		close (fbfd);
		return -1;
	}

	printf ("The framebuffer device was successfully mapped to memory\n");
	return 0;
}

struct pdef {
	int rs, rb, gs, gb, bs, bb;
	int swap;
};

struct pdef pdef_base = {
	.rs = 5, .rb = 11,
	.gs = 6, .gb = 5,
	.bs = 5, .bb = 0,
	.swap = 0,
};

struct sdef {
	void * base;
	int w, h, rowbyte, pixelsize;
};

uint16_t 
color2pdef(
	struct pdef *p,
	uint32_t color )
{
	uint32_t res =
		((((color >> 16) & 0xff) & ((1 << p->rs) - 1)) << p->rb) |
		((((color >> 8) & 0xff) & ((1 << p->gs) - 1)) << p->gb) |
		((((color >> 0) & 0xff) & ((1 << p->bs) - 1)) << p->bb);
	return p->swap ? ((res >> 8) && 0xff) | ((res & 0xff) << 8) : res;
}

uint16_t *
getsbase(
	struct sdef * s,
	int x, int y)
{
	return (uint16_t*)(((uint8_t*)s->base) + (y * s->rowbyte) + (x * s->pixelsize));
}

void
rfill(struct sdef * s, struct pdef *p,
	uint32_t color,
	int x, int y, int w, int h)
{
	uint16_t pix = color2pdef(p, color);
	
	uint16_t *d = getsbase(s, x, y);
	
	for (int ry = 0; ry < h; ry++) {
		uint16_t * r = d;
		int rw = w;
		while (rw--) *r++ = pix;
		d = (uint16_t *)(((uint8_t*)d) + s->rowbyte);
	}
}

void hline(struct sdef * s, struct pdef *p, uint32_t color, int x1, int y1, int x2)
{
	uint16_t pix = color2pdef(p, color);
	
	uint16_t *d = getsbase(s, x1, y1);
	x2 -= x1;
	while (x2--)
		*d++ = pix;
}
int 
main(
		int argc, 
		char ** argv)
{

	if (openfb()) {
		fprintf(stderr, "%s: could not open frame buffer console\n", argv[0]);
		exit(1);
	}
	printf("%s: Starting\n", argv[0]);

	struct sdef mfb = {
		.base = fbp,
		.w = vinfo.xres,
		.h = vinfo.yres,
		.rowbyte = (vinfo.xres * vinfo.bits_per_pixel) / 8,
		.pixelsize = vinfo.bits_per_pixel / 8,
	};
	
	for (int i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "-swap"))
			pdef_base.swap = !pdef_base.swap;
	}
	uint32_t color[3] = {
		(0xff << 16) | (0x00 << 8) | (0x00 < 0),
		(0x00 << 16) | (0xff << 8) | (0x00 < 0),
		(0x00 << 16) | (0x00 << 8) | (0xff < 0),
	};
	int w = (vinfo.xres - 5 - 5) / 3;
	int ci = 0;
	
	for (int i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "-swap"))
			pdef_base.swap = !pdef_base.swap;
		else if (!strcmp(argv[i], "-c")) {
			i++;
			uint32_t t;
			sscanf(argv[i], "%x", &t);
			printf("replace %08x with %08x\n", color[ci], t);
			color[ci] = t;
			ci = (ci + 1) % 3;
		} else
			printf("huh? '%s'\n", argv[i]);
	}
	
	for (int c = 0; c < 3; c++)
		rfill(&mfb, &pdef_base, color[c], 5 + (c * w), 5, w, vinfo.yres - 10);

	while (1) {
		sleep(1);
	}

	return 0;
}
