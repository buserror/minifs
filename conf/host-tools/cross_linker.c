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

#include <stdint.h>
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

typedef struct so_filelist_t {
	int count;
	int alloc;
	struct so_file_t ** file;
} so_filelist_t;

enum {
	DIR_RECURSIVE = 1,
	DIR_PLUGINS = 2,
	FILE_LOCK = 1,
	FILE_PURGED = 2,
};
typedef struct so_dir_t {
	struct so_dir_t * next;
	char * name;
	int flags;	// directory kind
	so_filelist_t * loaded;
	so_filelist_t * purged;
	so_filelist_t * symlink;
} so_dir_t;

typedef struct so_str_t {
	struct so_str_t * next;
	uint32_t kind;
	uint16_t hash;
	char *s;
	struct so_file_t * link;
} so_str_t;

typedef struct so_file_t {
	char * name;
	uint16_t hash;
	int flags;
	so_str_t *so_name;
	so_str_t *so_needed;
	so_filelist_t * used;
	char * symlink_value;
} so_file_t;

so_str_t * so_new(so_str_t * link, uint32_t kind, char * string)
{
	so_str_t * str = malloc(sizeof(so_str_t));
	str->next = link;
	str->link = NULL;
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
		// look it up in the symlinks too, in case we used a 'simple' name
		for (int fi = 0; dir->symlink && fi < dir->symlink->count; fi++) {
			so_file_t * f = dir->symlink->file[fi];
			if (f->hash == hash && !strcmp(f->name, filename))
				return so_dir_search(dir, f->symlink_value);
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
		printf("    soname %04x %s\n", str->hash, str->s);
		str = str->next;
	}
	str = file->so_needed;
	while (str) {
		printf("    needed %04x %s\n", str->hash, str->s);
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
	GElf_Ehdr elf_header;
	Elf *elf = NULL; /* Our Elf pointer for libelf */
	int fd; // File Descriptor

	if ((fd = open(file, O_RDONLY)) == -1) {
		perror(file);
		close(fd);
		return NULL;
	}

	elf = elf_begin(fd, ELF_C_READ, NULL);
	if (!elf) {
		printf("%s: %s NOT an ELF file\n", __func__, file);
		close(fd);
		return NULL;
	}
	if (gelf_getehdr(elf, &elf_header) == 0) {
		printf("%s: %s no ELF header\n", __func__, file);
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
			if (!name) {
				printf("%s %s: HAS NO STRING TABLE\n", __func__, file);
				exit(1);
			}
			if (strcmp(name, ".dynstr"))
				continue;
			Elf_Data *s = elf_getdata(scn, NULL);
			strings = s->d_buf;
		//	printf("Found dynamic string table\n");
		}
		if (shdr.sh_type != SHT_DYNAMIC)
			continue;

		Elf_Data *s = elf_getdata(scn, NULL);
		uint32_t size = s->d_size;
	//	printf("Walking elf dynamic section '%s' %d bytes\n", name, size);

		GElf_Dyn e;
		for (int i = 0; gelf_getdyn(s, i, &e) && e.d_tag != DT_NULL; i++) {
			switch (e.d_tag) {
				case DT_NEEDED: {
					res->so_needed = so_new(res->so_needed, 
						e.d_un.d_val, NULL);
				}	break;
				case DT_SONAME: {
					res->so_name = so_new(res->so_name, 
						e.d_un.d_val, NULL);
				}	break;
			}	
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
		printf("%s %s: so_name %p, so_needed %p !!\n", __func__, file, res->so_name, res->so_needed);
		
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
					sprintf(path, "%s/%s", dirname, e->d_name);
					so_file_t * elf = elf_read_dynamic(path);
					if (elf) {
					//	printf("File %s is loaded as ELF\n", path);
						elf->name = strdup(e->d_name);
						elf->hash = crc16_string(elf->name);
						res->loaded = so_filelist_add(res->loaded, elf);
					} 
				}
			}	break;
			case DT_LNK: {	// keep track of all links too
				so_file_t * ff = malloc(sizeof(so_file_t));
				memset(ff, 0, sizeof(so_file_t));
				ff->name = strdup(e->d_name);
				ff->hash = crc16_string(ff->name);
				res->symlink = so_filelist_add(res->symlink, ff);
				sprintf(path, "%s/%s", dirname, e->d_name);
				char out[256];
				ssize_t l = readlink(path, out, sizeof(out)-1);
				if (l > 0) {
					out[l] = 0;
					ff->symlink_value = strdup(out);
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
	so_dir_t * d;
	int total = 0;
	int cleared = 0;
	do {
		d = dir;
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
					//	printf("removing %s from %s [%d users left] \n", 
					//		f->name, n->s, found && found->used ? 
					//			found->used->count : 0);
						n = n->next;
					}

				} else
					fi++;
			}

			d = d->next;
		}
		total += cleared;
		printf("##### Purged %d libraires\n", cleared);
	} while (cleared);
	return total;
}

int purge_orphan_symlinks(so_dir_t * dir)
{
	int cleared = 0;
	do {
		cleared = 0;
		so_dir_t * d = dir;
		while (d) {
			for (int fi = 0; d->symlink && fi < d->symlink->count; fi++) {
				so_file_t *f = d->symlink->file[fi];
				if (f->flags & FILE_PURGED)
					continue;
				char path[4096], out[4096];
				int die = 0;
				sprintf(path, "%s/%s", d->name, f->name);

				ssize_t ln = readlink(path, out, sizeof(out)-1);
				if (ln == -1) {
					perror(f->name);
					die++;
				} else {
					char dpath[4096];
					out[ln] = 0;
					sprintf(dpath, "%s/%s", d->name, out);
					struct stat o;
					if (lstat(dpath, &o) == -1) {
					//	printf("DANGLING %s -> %s\n", f->name, out);
						die++; 
					}
					
				}
				if (die) {
					cleared++;
					f->flags |= FILE_PURGED;
					printf("Delete dangling link %s\n", path);
					unlink(path);
				}
			}
			d = d->next;
		}
		printf("Purged %d links\n", cleared);
	} while (cleared);
}

so_dir_t * load_root_directory(so_dir_t * dir, const char * name)
{
	const char * root[] = { "", "usr", "local", "opt", NULL };
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

int file_depends_on(so_file_t *f, so_str_t * onedep)
{
	if (!f)
		return 0;
	so_str_t * n = f->so_needed;

	while (n) {
		if (!n->link) {
			n = n->next;
			continue;
		}
		if (n->hash == onedep->hash && !strcmp(n->s, onedep->s))
			return 1;		
		n = n->next;
	}
	return 0;
}

int file_simplify_neededs(so_file_t *f)
{
	so_str_t * n = f->so_needed;
	printf("Processing %s\n", f->name);
	sp_file_dump(f);
	while (n) {
		if (!n->link) {
			n = n->next;
			continue;
		}

		so_str_t * nn = f->so_needed, *last = NULL;
	//	int found = 0;
		while (nn) {
			if (n != nn) {
			//	printf("SIM %s:     %s look for %s\n", f->name, n->s, nn->s);
				
				if (file_depends_on(n->link, nn)) {
				//	printf("SIM %s: %s already links to %s\n", f->name, n->s, nn->s);
					so_filelist_remove(nn->link->used, f);
				//	printf("SIM %s: Remove %s as dependency\n", f->name, nn->s);
					if (last)
						last->next = nn->next;
					else
						f->so_needed = nn->next;
				//	sp_file_dump(f);
				//	found++;	
				//	break;	
				}
			}
			last = nn;
			nn = nn->next;
		}
			
		n = n->next;
	}
	return 0;
	
}

FILE * invoke = NULL;

static char * my_getenv(const char *name)
{
	char * en = getenv(name);
	if (en && invoke)
		fprintf(invoke, "export %s=\"%s\"\n", name, en);
	return en;
}

int main(int argc, char * argv[])
{
	/* this is actually mandatory !! otherwise elf_begin() fails */
	elf_version(EV_CURRENT);

	so_dir_t * dir = NULL;
	int do_actual_purge = 0;

	if (getenv("CROSS_LINKER_INVOKE"))
		invoke = fopen(getenv("CROSS_LINKER_INVOKE"), "w");
	my_getenv("ROOTFS");
	my_getenv("ROOTFS_PLUGINS");
	my_getenv("ROOTFS_KEEPERS");
	my_getenv("ROOTFS_EXTRAS");
	my_getenv("CROSS_LINKER_DUMP");
	my_getenv("CROSS_LINKER_DEPS");
	if (invoke)
		fprintf(invoke, "gdb %s/staging-tools/bin/%s ", getenv("BUILD"), argv[0]);

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
		if (invoke)
			fprintf(invoke, "%s ", argv[pi]);
	}
	if (invoke) {
		fprintf(invoke, "\n");
		fflush(invoke);
	}
	/*
	 * Load parameters from the environment, if any
	 */
	char * env_root = getenv("ROOTFS");
	if (env_root)
		dir = load_root_directory(dir, env_root);

	char * extras = getenv("ROOTFS_EXTRAS");
	if (extras) {
		char * p;
		while ((p = strsep(&extras, ":")) != NULL) {
			if (!*p)
				continue;
			char path[4096];
			sprintf(path, "%s/%s", env_root, p);
			printf("load_root_directory extra '%s'\n", p);
			dir = load_root_directory(dir, path);			
		}
	}

	char * plugs = getenv("ROOTFS_PLUGINS");
	if (plugs) {
		char * p;
		while ((p = strsep(&plugs, ":")) != NULL) {
			if (*p) {
				printf("loading plugins '%s'\n", p);
				dir = elf_scandir(dir, p, DIR_PLUGINS|DIR_RECURSIVE);
			}
		}
	}
	char * keepers = getenv("ROOTFS_KEEPERS");
	if (keepers) {
		printf("Trying to protect %s\n", keepers);
		char * p;
		while ((p = strsep(&keepers, ":")) != NULL) {
			if (!*p)
				continue;
			so_file_t * found = so_dir_search(dir, p);
			if (found) {
				printf("Protecting %s/%s from purge\n", p, found->name);
				sp_file_dump(found);
				found->flags |= FILE_LOCK;
			}
		}
	}

	if (my_getenv("CROSS_LINKER_DUMP") && atoi(getenv("CROSS_LINKER_DUMP"))) {
		so_dir_t * d = dir;
		while (d) {
			printf("*** %s has %d files\n", d->name, d->loaded->count);
			for (int fi = 0; fi < d->loaded->count; fi++) {
				so_file_t *f = d->loaded->file[fi];
				sp_file_dump(f);
			}
			d = d->next;
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
					fprintf(stderr, "%s ## Warning file %s misses %s -- possible cross compile snafu\n",
						argv[0], f->name, n->s);
				} else {
					n->link = found;
					if (found->so_name)	// help create links
						so_set(n, n->kind, found->so_name->s);
					found->used = so_filelist_add(found->used, f);
				}
				n = n->next;
			}

		}
		d = d->next;
	}

	/* Next Pass, simplify links. Remove direct links from the files
	 * whole libraries are also linking that particular lib
	 */
	d = dir;
	while (d) {
		for (int fi = 0; d->loaded && fi < d->loaded->count; fi++) {
			so_file_t *f = d->loaded->file[fi];
			file_simplify_neededs(f);
		}
		d = d->next;
	}

	/*
	 * Next, remove any orphans, recursively
	 */
	purge_unused_libs(dir);

	/*
	 * Dump a graphviz
	 */
	if (getenv("CROSS_LINKER_DEPS")) {
		printf("%s: Creating cross-reference with graphviz\n", argv[0]);
		FILE *dot = fopen("._cross-linker.dot", "w");
		fprintf(dot, "digraph G { rankdir=LR; node [shape=rect];\n");
		d = dir;
		while (d) {
			for (int fi = 0; d->loaded && fi < d->loaded->count; fi++) {
				so_file_t *f = d->loaded->file[fi];
				if (f->used)
					fprintf(dot, "\"%s\" [label=\"(%d) %s\"]\n", 
						f->so_name ? f->so_name->s : f->name,
						f->used->count,
						f->so_name ? f->so_name->s : f->name);
				else
					fprintf(dot, "\"%s\"\n", 
						f->so_name ? f->so_name->s : f->name);

				for (int ui = 0; f->used && ui < f->used->count; ui++)
					fprintf(dot, "\"%s\" -> \"%s\"\n", 
						f->used->file[ui]->so_name ?
							f->used->file[ui]->so_name->s :
							f->used->file[ui]->name, 
						f->so_name ? f->so_name->s : f->name);
			}
			d = d->next;
		}
		fprintf(dot, "}\n");
		fclose(dot);
		system("dot -Tpdf -o._cross-linker.pdf ._cross-linker.dot");
	}
	/*
	 * print/delete, print who is not used
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
	/*
	 * Remove any lasting danling links
	 */
	if (do_actual_purge)  // now lasty cleanup unwanted symlinks
		purge_orphan_symlinks(dir);

}
