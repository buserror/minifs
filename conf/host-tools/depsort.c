/*
 * depsort.c
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
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define MAX_DEP 48

typedef struct pack_t {
	char * name;
	int moved;
	int depcount;
	char * dep[MAX_DEP];
} pack_t;

static pack_t * pp_lookup(pack_t *pp, size_t count, char * name)
{
	for (int i = 0; i < count; i++)
		if (!strcmp(pp[i].name, name))
			return &pp[i];
	return NULL;
}

int main()
{
	char * in = NULL;
	size_t inlen = 0, insize = 0;
	
	while (!feof(stdin)) {
		char line[4096];
		size_t l = fread(line, 1, sizeof(line), stdin);
		if (l > 0) {
			if (inlen + l > insize) {
				while (inlen + l > insize)
					insize += 4096;
				in = realloc(in, insize + 1);
			}
			memcpy(in + inlen, line, l);
			inlen += l;
			in[inlen] = 0;
		}
		if (l == 0)
			break;
	}
//	printf("read %d bytes\n", (int) inlen);
	
	pack_t *pp = NULL;
	int ppcount = 0;
	
	char * packlist = in;
	char * packend;
	while ((packend = strchr(packlist, ')')) != NULL) {
		char * pack = packlist;
		while (*pack == ' ')
			pack++;
		packlist = packend;
		*packlist++ = 0;

		char * ps = strchr(pack, '(');
		if (ps)
			*ps++ = 0;
		fprintf(stderr, "pack[%3d] '%s' [%s]\n", ppcount, pack, ps);	
		
		if (pp_lookup(pp, ppcount, pack)) {
			fprintf(stderr, "*** pack %s is already declared, ignoring\n", pack);
			continue;
		}
		if (!(ppcount % 8))
			pp = realloc(pp, sizeof(pack_t) * (ppcount+8));
		
		pack_t * d = &pp[ppcount++]; 
		pack_t zero = {0};
		*d = zero;
		d->name = strdup(pack);
		char * dep;
		while ((dep = strsep(&ps, " ")) != NULL) {
		//	printf("pack %s dep '%s'\n", pack, dep);
			if (d->depcount == MAX_DEP)
				fprintf(stderr, "*** Package %d overglows dependencies list\n", pack);
			else if (*dep)
				d->dep[d->depcount++] = strdup(dep);
		}
	}
	fprintf(stderr, "There are %d packages\n", ppcount);
	
	int swap = 0;
	do {
		swap = 0;
		fprintf(stderr, "### Pass\n");
		for (int i = 0; i < ppcount; i++) {
			pack_t *p = &pp[i];
			pack_t *de = NULL;
			for (int di = 0; di < p->depcount; di++) {
				if (!p->dep[di])
					continue;
				pack_t *dep = pp_lookup(pp, ppcount, p->dep[di]);
				if (!dep) {
					fprintf(stderr, "Package %s depends on '%s' (doesnt exists)\n", p->name, p->dep[di]);
					p->dep[di] = NULL;
				} else if (dep > de)
					de = dep;
			}
			if (de && de > p) {
				if (p->moved) {
					fprintf(stderr, "Pack %s was already moved!\n", p->name);
					if (p->moved > 5) {
						fprintf(stderr, "Circular dependency involving %s and %d detected, failing!\n", p->name, de->name);
						exit(1);
					}
				}
				p->moved++;
				fprintf(stderr, "Relocating %s after %s\n", p->name, de->name);
				swap++;
				pack_t copy = *p;
				memmove(p, p + 1, (char*)de - (char*)p);
				*de = copy;
				i--;	// we moved the array...
			}
		}
		fprintf(stderr, "Did %d swaps\n", swap);
	} while (swap > 0);

	FILE * o[] = { stdout, stderr, NULL };
	for (int oi = 0; o[oi]; oi++) {
		for (int i = 0; i < ppcount; i++)
			fprintf(o[oi], "%s ", pp[i].name);
		fprintf(o[oi], "\n");
	}
}
