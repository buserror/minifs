/*
 * fat_find.c
 *
 * (C) 2010 Michel Pollet <buserror@gmail.com>
 *
 * This tool is made to scan the system for FAT partitions that meet
 * a set of criteria, and allow quick extraction of files without
 * having to mount the filesystem.
 * The tool can also synlink the partition that matched to allow quick
 * access later to mount it if necessary.
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
#define _GNU_SOURCE	// for fnmatch
#define  _FILE_OFFSET_BITS 64
#include <features.h>
#include <sys/types.h>
#include <stdint.h>
#include <stdlib.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <ctype.h>
#include <dirent.h>
#include <sys/stat.h>
// from thirdparty
#include <libfatint.h>

#if !defined(__UCLIBC_MAJOR__) || defined(__UCLIBC_HAS_FNMATCH__)
#define CONFIG_FNMATCH 1
#include <fnmatch.h>
#endif

struct lookupList {
	int count;
	const char * name[32];
};


struct volume_id_file {
	char name[32];
	char longname[4 * 32 + 1];

	char lfn[4][32 + 1];

	int32_t cluster;
	uint32_t size;

    libfat_sector_t sector;
    int offset;
	struct fat_dirent entry;
};

struct volume_id_dir {
	int count;
	struct volume_id_file * entry;
};

struct volume_id {
	char dev[256];
	int removable, ro;
	int fd;
	size_t buffer_size;
	uint8_t *buffer;
	int uuid_type;
	char label[16];
	char uuid[64];

	struct libfat_filesystem * fat;
	struct volume_id_dir  root;
};

struct volume_id * g_libfat_volume_id = NULL;
int verbose = 0;

char * longname_extract(uint8_t * buf, char * dst)
{
	int src = 1;
	int cnt = 0;
	do {
		if (src == 11)
			src = 14;
		else if (src == 26)
			src = 28;
		else {
			if (buf[src] != 0 && buf[src] != 0xff)
				dst[cnt++] = buf[src];
			else
				break;
			src += 2;
		}
	} while (src < 32);
	dst[cnt] = 0;
	return dst;
}

char * shortname_extract(uint8_t * buf, char * dst)
{
	char * out = dst;
	for (int i = 0; i < 11; i++) {
		char s = buf[i];
		if (i == 0 && s == 0x05)
			s = 0xe5;
		if (s != ' ') {
			if (i == 8)
				*out++ = '.';
			*out++ = tolower(s);
		}
	}
	*out++ = 0;
	return dst;
}

static int
readfunc(
		intptr_t refcon,
		void *buf,
		size_t secsize,
		libfat_sector_t secno)
{
	struct volume_id *id = g_libfat_volume_id;
//	printf("%s read %s sector %d size %d (%d)\n", __func__, id->dev,
//			(int)secno, (int)secsize, (int)secno * (int)secsize);
	/*off_t offset =*/ lseek(id->fd, secno * secsize, SEEK_SET);
//	printf("%s %s read offset %d\n", __func__, id->dev, (int)offset);
	ssize_t r = read(id->fd, buf, secsize);
	if (r == -1) {
	//	printf("volume_id_get_buffer ERROR %ld\n", (long)r);
	//	perror("volume_id_get_buffer");
		return -1;
	}
	return secsize;
}


ssize_t
volume_id_read_file(
		struct volume_id *id,
		struct volume_id_file *file,
		int outfd)
{
	struct libfat_filesystem *fs = id->fat;
	libfat_sector_t s = libfat_clustertosector(fs, file->cluster);
	uint32_t size = file->size;

	if (verbose) {
		uint64_t sector = (uint64_t)s;
		uint64_t sector_cnt = (uint64_t)fs->end;
		printf("%s: file name     = %s\n", __func__, file->name);
		printf("%s: first cluster = %d\n", __func__, file->cluster);
		printf("%s: first sector  = %llu\n", __func__, sector);
		printf("%s: outfd         = %d\n", __func__, outfd);
		printf("%s: total sectors = %llu\n", __func__, sector_cnt);
		if (s == (libfat_sector_t) -1)
			printf("%s: libfat_nextsector() returned -1 before entering loop\n", __func__);
	}

	while (size) {
		if (s == 0)
			return -2; /* Not found */
		else if (s == (libfat_sector_t) -1)
			return -1; /* Error */

		uint8_t * block = libfat_get_sector(fs, s);
		if (!block)
			return -1; /* Read error */
		uint32_t data = size > LIBFAT_SECTOR_SIZE ? LIBFAT_SECTOR_SIZE : size;

		// printf("Writing %d (%8d remains)\n", data, size);
		write(outfd, block, data);
		size -= data;
		// flush the sector too, we don't want to keep data around!
		libfat_flush(fs);

		s = libfat_nextsector(fs, s);

		if (verbose) {
			if (s == (libfat_sector_t) -1)
				printf("%s: libfat_nextsector() returned -1 inside loop\n", __func__);
		}
	}
	ftruncate(outfd, file->size - size);

	return size;
}

#define FAT_ATTR_VOLUME_ID		0x08
#define FAT_ATTR_DIR			0x10
#define FAT_ATTR_LONG_NAME		0x0f
#define FAT_ATTR_MASK			0x3f
#define FAT_ENTRY_FREE			0xe5

int32_t
volume_id_read_dir(
		struct libfat_filesystem *fs,
		int32_t dirclust,
		struct volume_id_dir * dir)
{
	struct fat_dirent *dep;
	int nent;
	libfat_sector_t s = libfat_clustertosector(fs, dirclust);

	struct volume_id_file file;
	memset(&file, 0, sizeof(file));

	while (1) {
		if (s == 0)
			return -2; /* Not found */
		else if (s == (libfat_sector_t) -1)
			return -1; /* Error */

		dep = libfat_get_sector(fs, s);
		if (!dep)
			return -1; /* Read error */

		for (nent = 0; nent < LIBFAT_SECTOR_SIZE; nent
				+= sizeof(struct fat_dirent), dep++) {

			if (dep->name[0] == 0)
				return dir->count; /* Hit high water mark */

			if (dep->name[0] == FAT_ENTRY_FREE)
				continue;

			/* long name */
			if ((dep->attribute & FAT_ATTR_MASK) == FAT_ATTR_LONG_NAME) {
				int lfni = (((uint8_t*)dep)[0] & 0xf) - 1;
				if (lfni < 4)
					longname_extract((uint8_t*)dep, file.lfn[lfni]);
				continue;
			}

			if ((dep->attribute & (FAT_ATTR_VOLUME_ID | FAT_ATTR_DIR)) == FAT_ATTR_VOLUME_ID) {
				/* labels do not have file data */
				if (dep->clusthi != 0 || dep->clustlo != 0)
					continue;
				//res = dep->name;
			}
			for (int i = 0; i < 4; i++) {
			//	printf("lfn[%d] = '%s'\n", i, file.lfn[i]);
				strcat(file.longname, file.lfn[i]);
			}
			shortname_extract((uint8_t*)dep, file.name);
		//	printf("  %s: '%s'\n", file.name, file.longname);
			file.entry = *dep;
			file.sector = s;
			file.offset = nent;

			if ((file.size = read32(&dep->size)) == 0)
				file.cluster = 0; /* An empty file has no clusters */
			else
				file.cluster = read16(&dep->clustlo)
						+ (read16(&dep->clusthi) << 16);

			dir->entry = realloc(dir->entry, (dir->count+1) * sizeof(file));
			dir->entry[dir->count++] = file;
			memset(&file, 0, sizeof(file));
		}

		s = libfat_nextsector(fs, s);
	}
	return dir->count;
}

int
volume_id_open(struct volume_id *id, const char * name)
{
	memset(id, 0, sizeof(*id));
	id->fd = open(name, O_RDONLY);
	if (id->fd == -1) {
	//	perror(name);
		return -1;
	}
	strcpy(id->dev, name);
	return 0;
}

void
volume_id_close(struct volume_id * id)
{
	if (id->fd > 0)
		close(id->fd);
	id->fd = 0;
	if (id->buffer)
		free(id->buffer);
	id->buffer = NULL;
	id->buffer_size = 0;
}

/*
 * read a sys file containing an integer
 */
int read_sys_int(const char * path, const char * name, int * res)
{
	char fname[256];
	snprintf(fname, sizeof(fname), "%s/%s", path, name);
	int fd = open(fname, O_RDONLY);
	if (fd == -1)
		return -1;
	int s = read(fd, fname, sizeof(fname) -1);
	if (s >= 0) {
		fname[s] = 0;
		*res = atoi(fname);
	}
	close(fd);
	return 0;
}

int
filename_match(
	const char * name,
	const struct volume_id_file * file )
{
#ifdef CONFIG_FNMATCH
	return !fnmatch(name, file->longname, FNM_CASEFOLD) ||
			!fnmatch(name, file->name, FNM_CASEFOLD);
#else
	return !strcasecmp(name, file->longname) ||
			!strcasecmp(name, file->name);
#endif
}

int main(int argc, char ** argv)
{
	struct lookupList expect = {0};
	struct lookupList print = {0};
	struct lookupList copy = {0};
	const char * outdir = "/tmp/rw";
	const char * link = NULL; // "/tmp/rw/root";
	int list = 0, any = 0;
	int fd;

	for (int i = 1; i < argc; i++) {
		if (!strcmp("-e", argv[i]) || !strcmp("--expect", argv[i])) {
			expect.name[expect.count++] = argv[++i];
		} else if (!strcmp("-p", argv[i]) || !strcmp("--print", argv[i])) {
			print.name[print.count++] = argv[++i];
		} else if (!strcmp("-c", argv[i]) || !strcmp("--copy", argv[i])) {
			copy.name[copy.count++] = argv[++i];
		} else if (!strcmp("-o", argv[i]) || !strcmp("--out", argv[i])) {
			outdir = argv[++i];
		} else if (!strcmp("-l", argv[i]) || !strcmp("--link", argv[i])) {
			link = argv[++i];
		} else if (!strcmp("-L", argv[i]) || !strcmp("--list", argv[i])) {
			list++;
		} else if (!strcmp("-a", argv[i]) || !strcmp("--any", argv[i])) {
			any++;
		} else if (!strcmp("-v", argv[i])) {
			verbose++;
		} else {
			fprintf(stderr, "%s"
#ifdef CONFIG_FNMATCH
					" (with fnmatch support)"
#endif
					"\n"
					"\t[-e|--expect] <filename> : only select FS with <filename> present\n"
					"\t[-p|--print] <filename>] : print <filename> on console, if present\n"
					"\t[-o|--out] <dir> : destination for copied files (optional, def /tmp/rw)\n"
					"\t[-c|--copy] <filename> : copy <filename> to local directory\n"
					"\t[-l|--link] <name> : symlink found device to <name>\n"
					"\t[-L|--list] : print device+filename of 'expected' files found\n"
					"\t[-a|--any] : expect/list any of the files specified\n"
					"\t[-v] : verbose mode\n",
					argv[0]);
			exit(0);
		}
	}

	DIR * disks = opendir("/sys/block/");

	if (!disks) {
		fprintf(stderr, "%s: unable to open /sys/block\n", argv[0]);
		exit(1);
	}

	/*
	 * First scan the disks, and partitions for likely FAT filesystem, and gather them
	 * into a list.
	 */
	int partitionCount = 0;
	const int maxPart = 16;
	struct volume_id * partition[maxPart];

	struct dirent * disk;
	while ((disk = readdir(disks)) != NULL && partitionCount < maxPart) {
		if (strncmp(disk->d_name, "sd", 2) && strncmp(disk->d_name, "mmc", 3))
			continue;
	//	printf("disk %s\n", disk->d_name);
		char diskpath[128];
		snprintf(diskpath, sizeof(diskpath), "/sys/block/%s", disk->d_name);
		DIR * disk_dir = opendir(diskpath);
		struct dirent * part;
		int ro = -1;
		int removable = -1;
		read_sys_int(diskpath, "removable", &removable);
		read_sys_int(diskpath, "ro", &ro);
		if (verbose)
			printf("disk %s removable=%d read-only=%d\n", disk->d_name, removable, ro);
		int partcount = 0;

		int attempt_open_fat(const char * dev) {
			struct volume_id * tst = malloc(sizeof(*tst));
			if (volume_id_open(tst, dev) == 0) {
				g_libfat_volume_id = tst;
				tst->fat = libfat_open(readfunc, 0);
				if (tst->fat != NULL) {
					tst->removable = removable;
					tst->ro = ro;
					volume_id_read_dir(tst->fat, 0, &tst->root);
					if (verbose) {
						switch (tst->fat->fat_type) {
							case FAT12:
								printf("%s: FAT type = FAT12\n", __func__);
								break;
							case FAT16:
								printf("%s: FAT type = FAT16\n", __func__);
								break;
							case FAT28:
								printf("%s: FAT type = FAT28\n", __func__);
								break;
							default:
								printf("%s: FAT type = unknown (%d)\n", __func__,
										(int)tst->fat->fat_type);
								break;
						}
						printf("%s is a valid fat!\n", dev);
					}
					partition[partitionCount++] = tst;
					return 0;
				} else {
					volume_id_close(tst);
					free(tst);
				}
			} else
				free(tst);
			return -1;
		}
		while ((part = readdir(disk_dir)) != NULL && partitionCount < maxPart) {
			if (strncmp(part->d_name, disk->d_name, strlen(disk->d_name)))
				continue;
	//		printf("partition %s\n", part->d_name);
			partcount++;
			char dev[64];
			snprintf(dev, sizeof(dev), "/dev/%s", part->d_name);

			attempt_open_fat(dev);
		}
		if (partcount == 0) {
			// also attempt to read the whole 'disk' as a partition, this is needed
			// for windoze formatted USB sticks and such
			char dev[64];
			snprintf(dev, sizeof(dev), "/dev/%s", disk->d_name);
			attempt_open_fat(dev);
		}
		closedir(disk_dir);
	}
	closedir(disks);

	/*
	 * For each partition look to see if they have the 'expected' files, otherwise,
	 * discard it.
	 * If the partition is the one we look for, print & copy files from it
	 */
	for (int i = 0; i < partitionCount; i++) {
		struct volume_id *p = partition[i];
		if (!p)
			continue;
		if (verbose)
			printf("%s\n", p->dev);

		if (verbose)
			for (int j = 0; j < p->root.count; j++)
				printf("\t'%s':'%s' %u\n", p->root.entry[j].name,
						p->root.entry[j].longname,
						read32(&p->root.entry[j].entry.size));

		for (int ei = 0; ei < expect.count; ei++) {
			int found = 0;
			if (verbose)
				printf("%s (%d files): exect any: %d: '%s'\n",
						p->dev, p->root.count, any, expect.name[ei]);
			for (int j = 0; j < p->root.count; j++) {
				if (verbose) printf("%s: '%s'\n", p->dev, p->root.entry[j].longname);
				if (filename_match(expect.name[ei], &p->root.entry[j])) {
					found++;
					if (verbose)
						printf("%s: '%s' matches\n", p->dev, p->root.entry[j].longname);
					if (list) {
						char *name = p->root.entry[j].longname[0] ?
										p->root.entry[j].longname :
										p->root.entry[j].name;
						char * quot = "";
						for (char *s = name; *s && !quot; s++)
							if (index(" \'", *s))
								quot = "\"";
							else if (index("\"", *s))
								quot = "'";

						printf("%s%s%s ", quot, name, quot);
					}
					if (!any)
						break;
				}
			}
			if (!found && !any) {
				if (verbose)
					printf("%s: '%s' NOT found, discarding\n", p->dev, expect.name[ei]);
				p = partition[i] = NULL;
				break;
			}
		}
		if (!p)
			continue;
		if (!list)
			if (verbose)
				printf("%s ", p->dev);
		for (int pi = 0; pi < print.count; pi++) {
			for (int j = 0; j < p->root.count; j++) {
				if (filename_match(print.name[pi], &p->root.entry[j])) {

					if (verbose)
						printf("%s: print '%s' (%d)\n",
							p->dev, print.name[pi],
							(int)p->root.entry[j].size);
					printf("%s=", print.name[pi]); fflush(stdout);
					g_libfat_volume_id = p;
					volume_id_read_file(p, &p->root.entry[j], 1);
					printf(" ");
				}
			}
		}

		if (copy.count > 0)
			mkdir(outdir, 0755);

		chdir(outdir);
		if (link) {
			unlink(link);
			if (symlink(p->dev, link)) {
				perror(link);
			}
		}

		for (int pi = 0; pi < copy.count; pi++) {
			for (int j = 0; j < p->root.count; j++) {
				if (filename_match(copy.name[pi], &p->root.entry[j])) {
					int fd = -1;
					if (verbose)
						printf("%s: copy '%s' (%d) to %s\n",
							p->dev, copy.name[pi],
							(int)p->root.entry[j].size,
							outdir);

					if (strncmp(p->root.entry[j].name, p->root.entry[j].longname, 1) != 0) {
						if (verbose)
							printf("fat_find: special case for disks formatted on a Windows platform\n");

						/* This is a special case for disks formatted on a Windows */
						/* platform */

						/* When a disk is formatted on a Windows platform, the long */
						/* filename entry is sometimes not populated when the filename */
						/* is a short filename (i.e., 8.3 filename format) */
						fd = open(p->root.entry[j].name, O_CREAT|O_TRUNC|O_WRONLY, 0644);
					} else {
						fd = open(p->root.entry[j].longname, O_CREAT|O_TRUNC|O_WRONLY, 0644);
					}

					if (fd == -1) {
						fprintf(stderr, "%s could not copy %s from %s to %s\n", argv[0],
								p->root.entry[j].longname, p->dev, outdir);
					} else {
						g_libfat_volume_id = p;
						volume_id_read_file(p, &p->root.entry[j], fd);
						close(fd);
					}
				}
			}
		}
		printf("\n");
		// exit if we were copying files
		if (copy.count || link)
			exit(0);
	}
	exit(1);
}
