// gcc -O -g 
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <poll.h>
#include <unistd.h>

char logname[256];
FILE * o = NULL;


#define TRACE(w) if (o) {\
		fprintf(o, "%s %s: ", getenv("PACKAGE"), w);\
		for (int i = 0; argv[i]; i++) fprintf(o, "%s ", argv[i]);\
		fprintf(o,"\n"); fflush(o); \
	}
	
#define V(w) { \
	if (!o) {\
		o = fopen(logname, "a"); \
		if (!o) perror(logname);\
		TRACE("START");\
	}\
	if (o) { w ; fflush(o); } \
}

int main(int argc, char * argv[])
{
	const char *real_install = getenv("HOST_INSTALL");
	char fix[8192];
	
	sprintf(logname, "%s/._install_warnings.log", getenv("BUILD"));

	if (!real_install) {
		fprintf(stderr, "fake install needs it's real one !! bailing.\n");
		exit(1);
	}
	char * staging = getenv("STAGING");
	char * base = getenv("MINIFS_BASE");
	
	for (int i = 1; i < argc; ) {
		int del = 0;
		if (!strcmp(argv[i], "-o") && i < argc-1) {
			V(fprintf(o, "%s: Preventing chown %s on %s\n", getenv("PACKAGE"), argv[i+1], argv[argc-1]);)
			del = 2;
		} else if (!strcmp(argv[i], "-g") && i < argc-1) {
			V(fprintf(o, "%s: Preventing chgrp %s on %s\n", getenv("PACKAGE"), argv[i+1], argv[argc-1]);)
			del = 2;
		}
		if (del) {
			int cnt = argc-i-del+1;
			printf("install moving %d/%d elements from index %d to %d\n", cnt, argc, i+del, i);
			memmove(&argv[i], &argv[i+del], cnt * sizeof(char*));
			argc -= del;
		} else
			i++;
	}
	char * last = argv[argc-1];
	char * there = strstr(last + 1, base); // search to see if DESTDIR s duplicated
	if (there) {
		char * newp = strdup(there);
		argv[argc-1] = newp;
		V(fprintf(o, "%s: Duplicate staging removed %s -> %s\n", getenv("PACKAGE"), last, newp);)
	}
	if (last[0] == '/' && strncmp(last, base, strlen(base))) {
		if (strncmp(last, "/usr", 4) && getenv("INSTALL_USR"))
			sprintf(fix, "%s/usr%s", staging, last);
		else
			sprintf(fix, "%s%s", staging, last);
		argv[argc-1] = fix;
		
		V(fprintf(o, "%s: Fixing %s to staging\n", getenv("PACKAGE"), last);)
	}
	struct stat st;
	if (stat(last, &st) == 0) {
		if (!S_ISDIR(st.st_mode)) {
			V(fprintf(o, "%s: Fixing %s to a directory name\n", getenv("PACKAGE"), last);)
			char *l = strrchr(last, '/');
			if (l)
				l[1] = 0; // strip filename
		}
	}
	if (o) {
		TRACE("END");
		fclose(o);
	}	
	execvp(real_install, argv);
	perror(argv[0]);
	exit(127);
}
