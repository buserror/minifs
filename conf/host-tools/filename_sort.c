/*
 * filename_sort.c
 * 
 * (C) 2008-2011 Michel Pollet <buserror@gmail.com>
 * 
 * Sometime a five-liner of C saved tons of work
 * This one takes a bunch of filenames, an sort them
 * by filename.
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
