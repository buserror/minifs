/*
 * Search a pattern into an environment variable
 * Saves a few loops in bash script
 */
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>

#include <fnmatch.h>

int main(int argc, const char *argv[])
{
	const char * sep = " \t";
	const char * env = NULL;
	const char * what = NULL;
	int debug = 0;
	int exact = 0;

	for (int i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "-s") && i < argc-1)
			sep = argv[++i];
		else if (!strcmp(argv[i], "-v"))
			debug++;
		else if (!strcmp(argv[i], "-e"))
			exact++;
		else if (!env)
			env = argv[i];
		else if (!what)
			what = argv[i];
	}
	if (debug) 
		fprintf(stderr, "%s env = '%s' pattern = '%s' separator = '%s'\n",
			argv[0], env, what, sep);
	if (env && what) {
		char * data = getenv(env);
		if (data) {
			char * word;
			while ((word = strsep(&data, sep)) != NULL) {
				if (debug)
					fprintf(stderr, "%s testing '%s'\n", argv[0], word);
				if (exact) {
					if (!strcmp(word, what)) {
						if (debug)
							fprintf(stderr, "%s pattern found\n",
								argv[0]);
						exit(0);
					}
				} else {
					if (!fnmatch(what, word, 0)) {
						if (debug)
							fprintf(stderr, "%s '%s' matches '%s'\n",
								argv[0], word, what);
						exit(0);
					}
				}
			}
		} else if (debug)
			fprintf(stderr, "%s env '%s' not found in environment\n",
				argv[0], env);
	} else {
		fprintf(stderr, 
			"%s - search a pattern into a split env variable\n"
			"\t[-v] verbose mode\n"
			"\t[-s <string>] set separator, default ' '\n"
			"\t[-e] only exact match, default fnmatch(1)\n"
			"\t<environment variable name>\n"
			"\t<pattern to look for>\n",
			argv[0]);
	}
	if (debug)
		fprintf(stderr, "%s pattern not found\n", argv[0]);
	exit(1);
}
