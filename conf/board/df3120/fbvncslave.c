/*
 * fbvncslave.c
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
#include <rfb/rfbclient.h>

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

	if (ioctl(tty, VT_OPENQRY, &vt) < 0) {
		perror("ioctl VT_OPENQRY");
		return -1;
	}
	close(tty);

	char tty_name[32];
	sprintf(tty_name, "/dev/tty%d", vt);
	tty = open(tty_name, O_WRONLY|O_NDELAY);
	perror(tty_name);

	struct vt_stat vts;

	if (ioctl(tty, VT_GETSTATE, &vts) == -1) {
		perror("ioctl VT_GETSTATE");
		return -1;
	}
	if (ioctl(tty, VT_ACTIVATE, vt) == -1) {
		perror("ioctl VT_ACTIVATE");
		return -1;
	}
	if (ioctl(tty, VT_WAITACTIVE, vt) == -1) {
		perror("ioctl VT_WAITACTIVE");
		return -1;
	}
	if (ioctl(tty, KDSETMODE, KD_GRAPHICS) == -1) {
		perror("KDSETMODE, KD_GRAPHICS");
		return -1;
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

	if ((int)fbp == -1) {
		printf ("Error: failed to map framebuffer device to memory\n");
		close (fbfd);
		return -1;
	}

	printf ("The framebuffer device was successfully mapped to memory\n");
	return 0;
}

static rfbBool 
allocate(
		rfbClient* client)
{
	client->width = 320;
	client->height = 240;
	client->frameBuffer = fbp;
	return TRUE;
}

int 
main(
		int argc, 
		char ** argv)
{
	rfbClient* cl;

	if (openfb()) {
		fprintf(stderr, "%s: could not open frame buffer console\n", argv[0]);
		exit(1);
	}
	printf("%s: Starting\n", argv[0]);

	cl = rfbGetClient(5,3,2);
	cl->MallocFrameBuffer=allocate;
	cl->canHandleNewFBSize = FALSE;

	cl->format.depth = 16;
	cl->appData.requestedDepth = cl->format.depth;
	cl->format.redMax = (1 << 5) - 1;
	cl->format.greenMax = (1 << 6) - 1;
	cl->format.blueMax = (1 << 5) - 1;
	cl->format.redShift = 5 + 6;
	cl->format.greenShift = 5;
	cl->format.blueShift = 0;

	if (!rfbInitClient(cl, &argc, argv))
		return 1;

	while(1) {
		int i = WaitForMessage(cl, 500);
		if (i < 0)
			return 0;
		if (i)
	    	if (!HandleRFBServerMessage(cl))
				return 0;
	}

	return 0;
}
