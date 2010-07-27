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
	static char temp[1024ll ];
	int i;
	FILE * f = NULL;
	for (i = 2; i < argc; i++)
		if (!strncmp(argv[i], "/usr/lib", 8) || !strncmp(argv[i], "/lib", 4)) {
			if (!f) f = fopen("/tmp/ccfix.log", "a");
			fprintf(f, "%s FIXING %s %s\n", argv[0], getenv("MINIFS_PACKAGE"), argv[i]);
			sprintf(temp, "%s%s", getenv("STAGING"), argv[i]);
			argv[i] = strdup(temp);
		} else if (!strncmp(argv[i], "-L/usr/lib", 10)) {
			if (!f) f = fopen("/tmp/ccfix.log", "a");
			fprintf(f, "%s FIXING %s %s\n", argv[0], getenv("MINIFS_PACKAGE"), argv[i]);
			sprintf(temp, "-L%s%s", getenv("STAGING"), argv[i]+2);
			argv[i] = strdup(temp);
		}
	if (f) {
		for (i = 0; i < argc; i++) fprintf(f, "%s ", argv[i]); fprintf(f,"\n");
		fclose(f);
	}
	execvp(argv[1], argv+1);
	perror(argv[0]);
	exit(127);
}
