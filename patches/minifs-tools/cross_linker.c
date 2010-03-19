// gcc -O -g -std=gnu99 -lelf
/*
	cross_linker.c

	Copyright 2008, 2010 Michel Pollet <buserror@gmail.com>

	This program cross examines a root filesystem, loads all the elf
	files it can find, see what other library they load and then
	find the orphans. In then remove the orphans as "user" for it's
	dependencies and continues removing until everything has at least
	one user, OR is a program itself (ie, not a shared library)

	cross_linker is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	cross_linker is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with cross_linker.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <libelf.h>
#include <gelf.h>
#include <libgen.h>
#include <dirent.h>

/*
 * Use a quick crc16 to make filename comparison quicker
 */
static uint8_t _crc16_lh[16] = { 0x00, 0x10, 0x20, 0x30, 0x40, 0x50, 0x60,
        0x70, 0x81, 0x91, 0xA1, 0xB1, 0xC1, 0xD1, 0xE1, 0xF1 };
static uint8_t _crc16_ll[16] = { 0x00, 0x21, 0x42, 0x63, 0x84, 0xA5, 0xC6,
        0xE7, 0x08, 0x29, 0x4A, 0x6B, 0x8C, 0xAD, 0xCE, 0xEF };

static uint16_t crc16_u4(uint16_t crc, uint8_t val)
{
	uint8_t h = crc >> 8, l = crc & 0xff;
	uint8_t t = (h >> 4) ^ val;

	// Shift the CRC Register left 4 bits
	h = (h << 4) | (l >> 4);
	l = l << 4;
	// Do the table lookups and XOR the result into the CRC Tables
	h = h ^ _crc16_lh[t];
	l = l ^ _crc16_ll[t];
	return (h << 8) | l;
}

uint16_t crc16_update(uint16_t crc, uint8_t val)
{
	crc = crc16_u4(crc, val >> 4); // High nibble first
	crc = crc16_u4(crc, val & 0x0F); // Low nibble
	return crc;
}

uint16_t crc16_string(char * str)
{
	uint16_t crc = 0xffff;
	while (*str)
		crc = crc16_update(crc, *str++);
	return crc;
}

/*
 * data model for cross-referencing ELF files
 */
typedef struct so_str_t {
	struct so_str_t * next;
	uint32_t kind;
	uint16_t hash;
	char *s;
} so_str_t;

typedef struct so_filelist_t {
	int count;
	int alloc;
	struct so_file_t ** file;
} so_filelist_t;

enum {
	DIR_RECURSIVE = 1,
	DIR_PLUGINS = 2,
	FILE_LOCK = 1,
};
typedef struct so_dir_t {
	struct so_dir_t * next;
	char * name;
	int flags;	// directory kind
	so_filelist_t * loaded;
	so_filelist_t * purged;
} so_dir_t;

typedef struct so_file_t {
	char * name;
	uint16_t hash;
	int flags;
	so_str_t *so_name;
	so_str_t *so_needed;
	so_filelist_t * used;
} so_file_t;

so_str_t * so_new(so_str_t * link, uint32_t kind, char * string)
{
	so_str_t * str = malloc(sizeof(so_str_t));
	str->next = link;
	str->kind = kind;
	str->s = string ? strdup(string) : NULL;
	str->hash = string ? crc16_string(string) : 0;
	return str;
}

so_str_t * so_set(so_str_t * str, uint32_t kind, char * string)
{
	if (!str)
		return NULL;
	if (str->s)
		free(str->s);
	str->kind = kind;
	str->s = string ? strdup(string) : NULL;
	str->hash = string ? crc16_string(string) : 0;
	return str;
}

/* locate a shared object in a list of lists
 * search the filenames AND the soname
 */
so_file_t * so_dir_search(so_dir_t * dir, char * filename)
{
	if (!filename)
		return NULL;
	uint16_t hash = crc16_string(filename);
	while (dir) {
		for (int fi = 0; dir->loaded && fi < dir->loaded->count; fi++) {
			so_file_t * f = dir->loaded->file[fi];
			if (f->hash == hash && !strcmp(f->name, filename))
				return f;
			else {
				so_str_t * s = f->so_name;
				while (s) {
					if (s->hash == hash && !strcmp(s->s, filename))
						return f;
					s = s->next;
				}
			}
		}
		dir = dir->next;
	}
	return NULL;
}

so_filelist_t * so_filelist_add(so_filelist_t * list, so_file_t * file)
{
	if (!file)
		return list;
	if (!list) {
		list = malloc(sizeof(so_filelist_t));
		memset(list, 0, sizeof(so_filelist_t));
	}

	if (list->count + 1 >= list->alloc) {
		list->alloc += 16;
		list->file = realloc(list->file, list->alloc * sizeof(so_file_t*));
	}
	list->file[list->count++] = file;

	return list;
}

int so_filelist_remove(so_filelist_t * list, so_file_t * file)
{
	if (!file || !list)
		return 0;

	for (int i = 0; i < list->count; i++)
		if (list->file[i] == file) {
			memcpy(list->file + i, list->file + i + 1, 
				(list->count - i - 1) * sizeof(so_file_t*));
			list->count--;
			return 1;
		}

	return 0;
}


void sp_file_dump(so_file_t * file)
{
	printf("elf file %04x %s\n", file->hash, file->name);
	so_str_t * str = file->so_name;
	while (str) {
		printf("soname %04x %s\n", str->hash, str->s);
		str = str->next;
	}
	str = file->so_needed;
	while (str) {
		printf("needed %04x %s\n", str->hash, str->s);
		str = str->next;
	}
}

/*
 * Read the dynamic libraries needed for a file. There is no guarantee the
 * dynamic string table is present before the dynamic sections, so the
 * actual string loading is done at the end.
 */
so_file_t * elf_read_dynamic(const char * file)
{
	Elf32_Ehdr elf_header; /* ELF header */
	Elf *elf = NULL; /* Our Elf pointer for libelf */
	int fd; // File Descriptor

	if ((fd = open(file, O_RDONLY)) == -1 ||
		(read(fd, &elf_header, sizeof(elf_header))) < sizeof(elf_header)) {
		close(fd);
		return NULL;
	}

	elf = elf_begin(fd, ELF_C_READ, NULL);
	if (!elf) {
		close(fd);
		return NULL;
	}
	so_file_t * res = malloc(sizeof(so_file_t));
	memset(res, 0, sizeof(so_file_t));

	char * strings = NULL;
	Elf_Scn *scn = NULL;                   /* Section Descriptor */

	while ((scn = elf_nextscn(elf, scn)) != NULL) {
		GElf_Shdr shdr;                 /* Section Header */
		gelf_getshdr(scn, &shdr);
		char * name = elf_strptr(elf, elf_header.e_shstrndx, shdr.sh_name);

		if (shdr.sh_type == SHT_STRTAB) {
			if (strcmp(name, ".dynstr"))
				continue;
			Elf_Data *s = elf_getdata(scn, NULL);
			strings = s->d_buf;
//			printf("Found dynamic string table\n");
		}
		if (shdr.sh_type != SHT_DYNAMIC)
			continue;

		Elf_Data *s = elf_getdata(scn, NULL);
		uint32_t size = s->d_size;
//		printf("Walking elf dynamic section '%s' %d bytes\n", name, size);

		Elf32_Dyn * e = (Elf32_Dyn *)s->d_buf;

		while (e->d_tag != DT_NULL) {
			switch (e->d_tag) {
				case DT_NEEDED: {
					res->so_needed = so_new(res->so_needed, 
						e->d_un.d_val, NULL);
				}	break;
				case DT_SONAME: {
					res->so_name = so_new(res->so_name, 
						e->d_un.d_val, NULL);
				}	break;
			}
			e++;
		}
	}
	// load the actual string values now
	so_str_t * str = res->so_name;
	while (str) {
		char * name = strings + str->kind;
		so_set(str, DT_SONAME, name);
		str = str->next;
	}
	str = res->so_needed;
	while (str) {
		char * name = strings + str->kind;
		so_set(str, DT_NEEDED, name);
		str = str->next;
	}

	elf_end(elf);
	close(fd);

	if (!res->so_name && !res->so_needed) {
		free(res);
		res = NULL;
	}
	return res;
}

/*
 * Scan a directory for elf files
 */
so_dir_t * elf_scandir(so_dir_t * base, const char * dirname, int flags)
{
	DIR * d = opendir(dirname);
	if (!d)
		return base;

	so_dir_t * res = malloc(sizeof(so_dir_t));
	memset(res, 0, sizeof(so_dir_t));

	struct dirent * e;
	while ((e = readdir(d)) != NULL) {
		if (e->d_name[0] == '.')
			continue;
		char path[4096];
		switch (e->d_type) {
			case DT_DIR:
				if (flags & DIR_RECURSIVE) {
					printf("Loading directory %s/%s\n", 
						dirname, e->d_name);
					sprintf(path, "%s/%s", dirname, e->d_name);
					elf_scandir(base, path, flags);
				}
				break;
			case DT_REG: {
				char * end = strrchr(e->d_name, '.');
				if (!end || strcmp(end, ".a") && strcmp(end, ".la")) {
				//	printf("Loading %s:\n", e->d_name);
					sprintf(path, "%s/%s", dirname, e->d_name);
					so_file_t * elf = elf_read_dynamic(path);
					if (elf) {
						elf->name = strdup(e->d_name);
						elf->hash = crc16_string(elf->name);
						res->loaded = so_filelist_add(res->loaded, elf);
					}
				}
			}	break;
		}
	}
	closedir(d);
	if (res->loaded) {
		res->flags = flags;
		res->name = strdup(dirname);
		if (base) {
			so_dir_t *b = base;
			while (b->next)
				b = b->next;
			b->next = res;
		}
	} else {
		free(res);
		res = NULL;
	}
	return base ? base : res;
}

/*
 * Multi-pass removal of (so)files that are not used
 */
int purge_unused_libs(so_dir_t * dir)
{
	so_dir_t * d = dir;
	int total = 0;
	int cleared = 0;
	do {
		cleared = 0;
		while (d) {
			if (d->flags & DIR_PLUGINS) {
				d = d->next;
				continue;
			}
			for (int fi = 0; fi < d->loaded->count; ) {
				so_file_t *f = d->loaded->file[fi];

				if (f->so_name && (!f->used || !f->used->count) && !(f->flags & FILE_LOCK)) {
				//	printf("Library %s is not used\n", f->name);
					d->purged = so_filelist_add(d->purged, f);
					so_filelist_remove(d->loaded, f);
					cleared++;

					// remove this file as "user" of it's sub-needed bits
					so_str_t * n = f->so_needed;

					while (n) {
						so_file_t * found = so_dir_search(dir, n->s);
						if (found)
							so_filelist_remove(found->used, f);
				//		printf("removing %s from %s [%d users left] \n", 
				//			f->name, n->s, found && found->used ? 
				//				found->used->count : 0);
						n = n->next;
					}

				} else
					fi++;
			}

			d = d->next;
		}
		total += cleared;
//		printf("##### cleared %d\n", cleared);
	} while (cleared);
	return total;
}

so_dir_t * load_root_directory(so_dir_t * dir, const char * name)
{
	const char * root[] = { "", "usr", "local", NULL };
	const char * load[] = { "lib", "bin", "sbin", NULL };
	for (int ri = 0; root[ri]; ri++) {
		const char * r = root[ri];
		for (int li = 0; load[li]; li++) {
			char path[4096];
			sprintf(path, "%s/%s/%s", name, r, load[li]);
			dir = elf_scandir(dir, path, 0);
		}
	}
	return dir;
}

int main(int argc, char * argv[])
{
	/* this is actualy mandatory !! otherwise elf_begin() fails */
	elf_version(EV_CURRENT);

	so_dir_t * dir = NULL;
	int do_actual_purge = 0;

	for (int pi = 1; pi < argc; pi++) {
		if (!strcmp(argv[pi], "--root")) {
			const char * base = argv[++pi];
			dir = load_root_directory(dir, base);
		} else if (!strcmp(argv[pi], "--add")) {
			const char * name = argv[++pi];
			dir = elf_scandir(dir, name, DIR_PLUGINS|DIR_RECURSIVE);
		} else if (!strcmp(argv[pi], "--purge")) {
			do_actual_purge++;
		}
	}
	/*
	 * Load parameters from the environment, if any
	 */
	char * env_root = getenv("ROOTFS");
	if (env_root)
		dir = load_root_directory(dir, env_root);
	char * plugs = getenv("ROOTFS_PLUGINS");
	if (plugs) {
		char * p;
		while ((p = strsep(&plugs, ":")) != NULL) {
			if (*p)
				dir = elf_scandir(dir, p, DIR_PLUGINS|DIR_RECURSIVE);
		}
	}
	char * keepers = getenv("ROOTFS_KEEPERS");
	if (keepers) {
		char * p;
		while ((p = strsep(&keepers, ":")) != NULL) {
			if (!*p)
				continue;
			so_file_t * found = so_dir_search(dir, p);
			if (found) {
				printf("Protecting %s from purge\n", found->name);
				found->flags |= FILE_LOCK;
			}
		}
	}


	/*
	 * First pass, look at all the files, and add
	 * them as users for all of the other ones.
	 */
	so_dir_t * d = dir;
	while (d) {
		printf("%s has %d files\n", d->name, d->loaded->count);
		for (int fi = 0; fi < d->loaded->count; fi++) {
			so_file_t *f = d->loaded->file[fi];
			so_str_t * n = f->so_needed;

			while (n) {
				so_file_t * found = so_dir_search(dir, n->s);
				if (!found) {
					printf("## Warning file %s misses %s\n",
						f->name, n->s);
				} else {
					found->used = so_filelist_add(found->used, f);
				}
				n = n->next;
			}

		}
		d = d->next;
	}

	/*
	 * Second pass, remove any orphans, recursively
	 */
	purge_unused_libs(dir);
	
#if 0
	FILE *dot = fopen("._cross-linker.dot", "w");
	fprintf(dot, "digraph G { rankdir=LR; node [shape=rect];\n");
	d = dir;
	while (d) {
		for (int fi = 0; d->loaded && fi < d->loaded->count; fi++) {
			so_file_t *f = d->loaded->file[fi];
			fprintf(dot, "\"%s\"\n", f->name);

			for (int ui = 0; f->used && ui < f->used->count; ui++)
				fprintf(dot, "\"%s\" -> \"%s\"\n", 
					f->used->file[ui]->name, f->name);
		}
		for (int fi = 0; d->purged && fi < d->purged->count; fi++) {
			so_file_t *f = d->purged->file[fi];
			fprintf(dot, "\"%s\" [color=gray];\n", f->name);

			for (int ui = 0; f->used && ui < f->used->count; ui++)
				fprintf(dot, "\"%s\" -> \"%s\"\n", 
					f->used->file[ui]->name, f->name);
		}
		d = d->next;
	}
	fprintf(dot, "}\n");
	fclose(dot);
#endif
	/*
	 * last pass, print who is not used
	 */
	d = dir;
	while (d) {
		for (int fi = 0; d->purged && fi < d->purged->count; fi++) {
			so_file_t *f = d->purged->file[fi];
			char cmd[4096];
			sprintf(cmd, "rm -f %s/%s", d->name, f->name);
			printf("%s\n", cmd);
			if (do_actual_purge)
				system(cmd);
		}
		d = d->next;
	}

}
