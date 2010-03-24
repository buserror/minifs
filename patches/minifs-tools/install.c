// gcc -O -g 

#include <sys/wait.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <poll.h>
#include <unistd.h>

int main(int argc, char * argv[])
{
	const char *real_install = getenv("HOST_INSTALL");

	if (!real_install) {
		fprintf(stderr, "fake install needs it's real one !! bailing.\n");
		exit(1);
	}
	char * staging = getenv("STAGING");
	char * rootfs = getenv("ROOTFS");
	char * last = argv[argc-1];
	char fix[4096];
	if (strncmp(last, staging, strlen(staging)) && strncmp(last, rootfs, strlen(rootfs))) {
		sprintf(fix, "%s/._install_warnings.log", getenv("BUILD"));
		FILE * o = fopen(fix, "a");
		if (strncmp(last, "/usr", 4) && getenv("INSTALL_USR"))
			sprintf(fix, "%s/usr%s", staging, last);
		else
			sprintf(fix, "%s%s", staging, last);
		argv[argc-1] = fix;
		if (o) {
			fprintf(o, "%s: Fixing %s to staging\n", getenv("PACKAGE"), last);
			fclose(o);
		}
	}
	execvp(real_install, argv);
	perror(argv[0]);
	exit(127);
}
