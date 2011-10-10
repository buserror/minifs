/*
 * waitfor_uevent.c
 *
 * (C) 2011 Michel Pollet <buserror@gmail.com>
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#include <sys/select.h>
#include <sys/time.h>
#include <unistd.h>
#include <fnmatch.h>
#include <stdint.h>

#include <linux/types.h>
#include <linux/netlink.h>


int main(int argc, char *argv[])
{
	struct sockaddr_nl nls;
	char buf[4096];
	long timeout = 0;
	int lookupCount = 0;
	struct {
		char * key;
		char * val;
	} lookup[16];
	int verbose = getenv("VERBOSE") ? atoi(getenv("VERBOSE")) : 0;

	if (argc < 3) {
		fprintf(stderr, "%s <timeout> KEY=val ...\n", argv[0]);
		exit(1);
	}
	timeout = atoi(argv[1]);
	if (timeout <= 0) {
		fprintf(stderr, "%s <timeout> Invalid timeout value %ld\n", argv[0], timeout);
		exit(1);
	}

	for (int i = 2; i < argc; i++) {

		char *equal = strchr(argv[i], '=');
		if (!equal) {
			fprintf(stderr, "%s <timeout> KEY=val ... Invalid argument '%s'\n", argv[0], argv[i]);
			exit(1);
		}
		int off = equal - argv[i];
		lookup[lookupCount].key = strdup(argv[i]);
		lookup[lookupCount].key[off] = 0;
		lookup[lookupCount].val = lookup[lookupCount].key + off + 1;
		lookupCount++;
	}
	// Open hotplug event netlink socket

	memset(&nls, 0, sizeof(struct sockaddr_nl));
	nls.nl_family = AF_NETLINK;
	nls.nl_pid = getpid();
	nls.nl_groups = -1;

	int fd = socket(PF_NETLINK, SOCK_DGRAM, NETLINK_KOBJECT_UEVENT);
	if (fd == -1) {
		fprintf(stderr, "%s socket(PF_NETLINK) failed; not root\n", argv[0]);
		exit(1);
	}

	// Listen to netlink socket

	if (bind(fd, (void *) &nls, sizeof(struct sockaddr_nl))) {
		fprintf(stderr, "%s bind(PF_NETLINK) failed\n", argv[0]);
		exit(1);
	}

	struct timeval tim = {0};
	tim.tv_usec = timeout * 1000;
	while (1) {
		fd_set rd;
		FD_ZERO(&rd);
		FD_SET(fd, &rd);
		int ret = select(fd + 1, &rd, NULL, NULL, &tim);

		if (ret == 0)
			break;
		int len = recv(fd, buf, sizeof(buf), MSG_DONTWAIT);
		if (len == -1) {
			fprintf(stderr, "%s recv(PF_NETLINK) failed\n", argv[0]);
			exit(1);
		}
		if (!strcmp(buf, "libudev"))	// udev, if running, polutes the netlink
			continue;
		if (verbose > 1)
			printf("###### (%ld/%ld) udev packet %d\n",
					timeout - (tim.tv_usec / 1000), timeout, len);

		int i = 0;
		char * src = buf;
		uint16_t found = 0;
		while (i < len) {
			if (verbose)
				printf("> %s (offset %d)\n", src, (int)(src-buf));

			char * equal = strchr(src, '=');
			for (int li = 0; li < lookupCount; li++) {
				int kl = equal - src;
				if (kl == strlen(lookup[li].key) &&
						!strncmp(lookup[li].key, src, kl)) {
					if (fnmatch(lookup[li].val, equal+1, 0) == 0) {
						found |= (1 << li);
						printf("Found match %s=%s for %s\n",
								lookup[li].key, lookup[li].val, src);
					} else {
						printf("didn't match %s=%s for %s\n",
								lookup[li].key, lookup[li].val, src);
						break;
					}
				}
			}
		//	printf("match mask %04x should be %04x\n", found, (1 << lookupCount)-1);
			if (found == (1 << lookupCount)-1) {
				printf("%s: (%ld/%ld) Event matched !\n", argv[0],
						timeout - (tim.tv_usec / 1000), timeout);
				exit(0);
			}
			int l = strlen(src) + 1;
			i += l;
			src += l;
		}
	}
	fprintf(stderr, "%s timeout, no matching event\n", argv[0]);
	exit(1);
}
