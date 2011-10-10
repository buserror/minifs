/*
 * pkg-config.c
 * 
 * (C) 2008-2011 Michel Pollet <buserror@gmail.com>
 * 
 * this program sits under pkg-config and makes sure the 
 * pathnames returned are all properly relative to the staging 
 * directory.
 * Since pkg-config is buggy it has to do some massaging
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
#include <sys/wait.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <poll.h>
#include <unistd.h>

int main(int argc, char * argv[])
{
	int ex = 0;
	int pipefd[2];
	char buf[4096];
	int rd, i;
	FILE *o =  fopen("/tmp/pkg-config.log", "a");

	char * package = getenv("MINIFS_PACKAGE");
	char * staging = getenv("STAGING");
	if (!staging)
		staging = "STAGING";
	int stagingl = strlen(staging);

	char pfx[512];
	char * nargv[128];
	int nargc = argc;
	int di = 1;

	int insert_path = 1;

	for (i = 1; i < argc; i++)
		if (!strcmp(argv[i], "--atleast-pkgconfig-version") ||
		    !strcmp(argv[i], "--max-version") ||
		    !strcmp(argv[i], "--exact-version") ||
		    !strcmp(argv[i], "--atleast-version"))
			insert_path = 0;
	
	nargv[0] = "/usr/bin/pkg-config";

	if (insert_path) {
		nargv[di++] = pfx;
		sprintf(pfx, "--define-variable=prefix=%s%s", staging, getenv("PACKAGE_PREFIX"));
	}
	// copy the other arguments
	fprintf(o, "%s ", package);
	for (i = 1; i < argc; i++) {
		fprintf(o, "%s ", argv[i]);
		nargv[di++] = argv[i];
	}
	nargv[di] = NULL;
	nargc = di;
	
	fprintf(o, "\n");
	fflush(stdout);

	errno=0;
	pipe(pipefd);

	pid_t pid = fork();
	if (pid == 0) {
	//	setenv("PKG_CONFIG_ALLOW_SYSTEM_CFLAGS", "1", 1);
	//	setenv("PKG_CONFIG_ALLOW_SYSTEM_LIBS", "1", 1);		
		close(1);
		dup2(pipefd[1], 1);
		execv(nargv[0], nargv);
	}
	close(pipefd[1]);
	rd = read(pipefd[0], buf, sizeof(buf)-1);
	waitpid(pid, &ex, 0);
	ex =  WEXITSTATUS(ex);
	
	buf[rd] = 0;
	while (rd > 0) {
		if (buf[rd-1] != '\n')
			break;
		buf[--rd] = 0;
	}
	if (rd > 0)
		fprintf(o, "%s %s\n", package, buf);
	else
		fprintf(o, "%s (return %d)\n", package, WEXITSTATUS(ex));		


	char out[8192];
	char *src = buf, *dst = out;
	int space = 1;
	
	while (*src) {
		if (space) {
			int l = 0;
			while (src[l] && src[l] != ' ')
				l++;
			*dst = 0;
			if (src[0] == '/' && strncmp(src, staging, stagingl))
				sprintf(dst, "%s", staging);
			else if (src[0] == '-' && 
				  (src[1] == 'L' || src[1] == 'I') &&
				  strncmp(src + 2, staging, stagingl)) {
				sprintf(dst, "%c%c%s", src[0], src[1], staging);
				src += 3;
			}
			dst += strlen(dst);
		}
		
		space = *src == ' ';
		*dst++ = *src++;
	}
	*dst = 0;

	if (*out && strcmp(buf, out))
		fprintf(o, "%s FIXED %s\n", package, out);
	if (*out) {
		write(1, out, dst-out); write(1, "\n", 1);
	}
	
	exit (ex);
}
