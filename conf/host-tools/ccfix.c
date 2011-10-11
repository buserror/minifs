/*
 * ccfix 
 * 
 * (c) Michel Pollet <buserror@gmail.com>
 * 
 * ccfix watches the command line passed to the compiler for things
 * that shouldn't be there. It also try to fix a few of them, as
 * sometime hacking the oackage is just too much trouble.
 * 
 * + Look for absolute (host) paths in -L and -I
 *   And replace them with equivalents in $STAGING
 * + Look for absolute pathnames, and fix them too
 * + Detects object-generating vs linking use of gcc
 * + Make sure there's a -march= passed to the line, since
 *   minifs /always/ use one, it should be there otherwise
 *   it meand the pacakge has lost it's CFLAGS
 * + Delete libtool parameters, if any
 *   Some packages break with libtool, so we remove any libtool
 *   parameters that might be lurking.
 * The command line is rebuilt before the real compiler is called
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

#include <sys/wait.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <poll.h>
#include <unistd.h>
#include <stdarg.h>

FILE * out = NULL;

void T(const char * fmt, ...)
{
	if (!out) {
		out = fopen("/tmp/ccfix.log", "a");
		fprintf(out, "ccfix:%s ", getenv("MINIFS_PACKAGE"));
	}
	va_list vap;
	va_start(vap, fmt);
	vfprintf(out, fmt, vap);
	va_end(vap);
}

int main(int argc, char * argv[])
{
	static char temp[1024];
	int i, di;
	FILE * f = NULL;
	const char * dc = NULL;
	const char * march = NULL;
	const char * pack = getenv("MINIFS_PACKAGE");
	const char * conftest = NULL;
	
	for (i = 2; i < argc; i++)
		if (!strncmp(argv[i], "/usr/lib", 8) || !strncmp(argv[i], "/lib", 4)) {
			T("[FIXING %s] ", argv[i]);
			sprintf(temp, "%s%s", getenv("STAGING"), argv[i]);
			argv[i] = strdup(temp);
		} else if (!strncmp(argv[i], "-L/usr/lib", 10)) {
			T("[FIXING %s] ", argv[i]);
			sprintf(temp, "-L%s%s", getenv("STAGING"), argv[i]+2);
			argv[i] = strdup(temp);
		} else if (!strncmp(argv[i], "-I/usr/include", 14)) {
			T("[FIXING %s] ", argv[i]);
			sprintf(temp, "-I%s%s", getenv("STAGING"), argv[i]+2);
			argv[i] = strdup(temp);
		} else if (!strcmp(argv[i], "-c")) {
			dc = argv[i];
		} else if (!strncmp(argv[i], "-march=", 7)) {
			march = argv[i];
		} else if (!strcmp(argv[i], "-rpath") || !strcmp(argv[i], "-version-info")) {
			T("[FIXING libtool lost options %s] ", argv[0], pack, argv[i]);
			argv[i++] = NULL; argv[i] = NULL;
		} else if (!conftest && argv[i][0] != '/' && strstr(argv[i], "conftest.c")) {
			conftest = argv[i];
		}
	if (dc) {
		if (!march && !conftest) {
			T("[WARN missing -march=] ");
		}
	}
	for (i = 2, di = 2; i < argc; i++) {
		if (argv[i])
			argv[di++] = argv[i];
	}
	argc = di;
	argv[argc] = NULL;
	
	if (out) {
		for (i = 1; i < argc; i++) T("%s ", argv[i]); 
		T("\n");
		fclose(out);
	}
	execvp(argv[1], argv+1);
	perror(argv[0]);
	exit(127);
}
