/*
 * Sometime a five-liner of C saved tons of work
 * 
 * This one takes a bunch of filenames, an sort them
 * by filename
 */ 
#include <libgen.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

int compar(const void *p1, const void *p2)
{
	char * s1 = *((char**)p1);
	char * s2 = *((char**)p2);
	return strcmp(basename(s1), basename(s2));
}

int main(int argc, char ** argv)
{
	int i;
	
	if (argc == 1)
		exit(0);
		
	qsort(argv+1, argc-1, sizeof(char*), compar);

	for (i = 1; i < argc; i++) {
		char * white = strchr(argv[i], ' ');
		if (white)
			printf("\"%s\" ", argv[i]);
		else
			printf("%s ", argv[i]);		
	}
	printf("\n");
}
