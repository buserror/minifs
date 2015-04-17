/*
 * uboot_env.c
 *
 * (C) 2015 Michel Pollet <buserror@gmail.com>
 *
 * Init, load, save u-boot environment from linux
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
 *
 * For testing purposes, you can use:
	modprobe nandsim first_id_byte=0x20 second_id_byte=0xaa \
		third_id_byte=0x00 fourth_id_byte=0x15
 */

/*
 * This tool allows access to the u-boot environment; it has been
 * tailored to pair with a u-boot already compiled, it will extract
 * the default envoronment from u-boot binary and allow linux to
 * 'reset' (initialize, provision) the env, but also to add, edit
 * and delete variables.
 * It can be used to set the ethernet address for example:
 * uboot_env -d /dev/mtd2 eth=ca:fe:f0:0d:d0:0d
 * Or to print the environment values, either as they are, or as shell
 * friendly variables like:
 * uboot_env -d /dev/mtd2 -S eth eth1
 * ETH=eth=ca:fe:f0:0d:d0:0d
 * So a shell script can 'eval' this easily.
 * 
 * It it also designed to work on NAND, skip the bad blocks etc
 */
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <ctype.h>

#define  __user	/* nothing */
#include <mtd/mtd-user.h>

#include CONFIG_H

#ifndef CONFIG_ENV_MTD
#define CONFIG_ENV_MTD "/dev/mtd2"
#endif

uint32_t  crc32 (uint32_t crc, const uint8_t *p, unsigned len);

int env_size = CONFIG_ENV_SIZE;
int verbose = 0;

/* Flash device */
typedef struct flash_t {
	int 		fd;
	const char 	*name;
	unsigned	 writeable : 1;
	struct mtd_info_user mtd;
	struct stat 	st;
} flash_t, *flash_p;

enum {
	ELOAD_OK = 0,
	ELOAD_INIT,
	ELOAD_CRC,
	ESAVE_OVERFLOW,
};


enum {
	LOAD_FORCE_INIT = (1 << 0),
	LOAD_IGNORE_CRC = (1 << 1),
	ENV_WRITEABLE	= (1 << 2),
};

/* This is the decompressed representation of env variables */
typedef struct env_t {
	int		state;
	int		count;
	struct {
		const char *name;
		const char *val;
	} e[0];
} env_t, *env_p;


/* flash representation of the environment, including mapping of bad blocks */
typedef struct flash_env_t {
	flash_p		flash;
	env_p		env;
	const char  	*raw;
	/* where this was loaded/saved from/to */
	loff_t		offset;
	/* actual lenght that was read from flash */
	size_t		loaded_size;
	/* env size, as specified by uboot */
	size_t		size;
	/* Same, padded to erase block size */
	size_t		padded_erase;
	/* Same, padded to write block size */
	size_t		padded_write;
} flash_env_t, *flash_env_p;

env_p
env_add(
	env_p env,
	const char * name,
	const char * val)
{
	if (!(env->count % 8))
		env = realloc(env, sizeof(*env) +
			((env->count + 8) * sizeof(env->e[0])));
	env->e[env->count].name = name;
	env->e[env->count].val = val;
	env->count++;
	return env;
}

/* it is OK to call this with NULL, to get an empty env */
env_p
env_load(
	const char *raw_env)
{
	env_p res = calloc(1, sizeof(*res));
	const char * s = raw_env;

	if (!res || !s)
		return res;

	while (*s) {
		const char * n = s;
		const char * e = NULL;
		while (*n) {
			if (*n == '=' && !e)
				e = n;
			n++;
		}
		if (e) {
			res = env_add(res, strndup(s, e-s), strdup(e + 1));
		} else
			printf("%s INVALID env line: %s\n", __func__, s);
		s = n + 1;
	};
	return res;
}

void
env_clear(
	env_p env)
{
	for (int i = 0; i < env->count; i++) {
		free((char*)env->e[i].name);
		free((char*)env->e[i].val);
	}
	env->count = 0;
}

void
env_free(
	env_p env)
{
	env_clear(env);
	free(env);
}

int
env_locate(
	env_p env,
	const char * name )
{
	for (int i = 0; i < env->count; i++) {
		if (!strcasecmp(env->e[i].name, name))
			return i;
	}
	return -1;
}

/*
 * Set, or clear the variable 'name'; if val is NULL (or *val is 0)
 * and the variable exists, it is cleared. Otherwise it is set, or added
 * if it wasn't there in the first place
 */
env_p
env_set(
	env_p env,
	const char * name,
	const char * val )
{
	int i = env_locate(env, name);
	int clear = !val || !*val;

	if (verbose)
		printf("%s name:'%s' value:'%s'\n", __func__, name, val);
	if (i >= 0 && clear) {
		free((char*)env->e[i].name);
		free((char*)env->e[i].val);
		env->e[i].name = env->e[i].val = NULL;
		return env;
	}
	if (clear)
		return env;
	if (i == -1)
		return env_add(env, strdup(name), strdup(val));
	if (env->e[i].val)
		free((char*)env->e[i].val);
	env->e[i].val = strdup(val);
	return env;
}

/*
 * Deserialize and serialize functions
 */
static env_p
rawenv_load(
	const char * raw_env,
	uint16_t flags )
{
	uint32_t tot_size = env_size - sizeof(uint32_t);
	uint32_t crc = crc32(0, (uint8_t*)raw_env, tot_size);
	uint32_t wanted = *((uint32_t*)(raw_env + tot_size));
	int err = ELOAD_OK;
	env_p env = NULL;

	if (verbose)
		printf("%s env size %d, crc %08x wanted %08x\n",
			__func__, env_size, wanted, crc);

	if (crc != wanted)
		err = ELOAD_CRC;
	if (err && *(((uint32_t*)raw_env)) == ~0)
		err = ELOAD_INIT;

	if (err == ELOAD_OK && (flags & LOAD_FORCE_INIT))
		err = ELOAD_INIT;

	switch (err) {
		case ELOAD_CRC:
			if ((flags & LOAD_IGNORE_CRC)) {
				env = env_load(raw_env);
				if (env && env->count) {
					env->state = err;
					break;
				}
				if (env)
					env_free(env);
			}
			// fallthru to init
		case ELOAD_INIT:
			env = env_load((char*)uboot_environment);
			env->state = err;
			break;
		case ELOAD_OK:
			env = env_load(raw_env);
	}
	return env;
}

static int
rawenv_save(
	env_p env,
	char *raw_env)
{
	uint32_t tot_size = env_size - sizeof(uint32_t);

	memset(raw_env, -1, env_size);

	char *d = raw_env;
	for (int i = 0; i < env->count; i++) {
		// deleted or empty content variable
		if (!env->e[i].name || !env->e[i].val)
			continue;
		if (d + strlen(env->e[i].name) +
			strlen(env->e[i].val) + 3 >= raw_env + tot_size)
			return ESAVE_OVERFLOW;
		memcpy(d, env->e[i].name, strlen(env->e[i].name));
		d += strlen(env->e[i].name);
		*d++ = '=';
		memcpy(d, env->e[i].val, strlen(env->e[i].val));
		d += strlen(env->e[i].val);
		*d++ = 0;
	}
	*d++ = 0;
	*d++ = 0;	// just in case the env is totally empty!
	uint32_t crc = crc32(0, (uint8_t*)raw_env, tot_size);
	*((uint32_t*)(raw_env + tot_size)) = crc;
	return 0;
}

/*
 * Flash device open/load/save/close functions
 */
void
flash_close(
	flash_p f )
{
	if (!f) return;
	if (f->name)
		free((char*)f->name);
	if (f->fd != -1)
		close(f->fd);
	free(f);
}

flash_p
flash_open(
	const char * name,
	uint16_t flags )
{
	flash_p f = calloc(1, sizeof(*f));

	f->fd = open(name, O_EXCL | (flags & ENV_WRITEABLE) ? O_RDWR : O_RDONLY);
	if (f->fd == -1) {
		fprintf(stderr, "%s: open %s: %s\n", __func__,
			name, strerror(errno));
		goto error;
	}
	f->name = strdup(name);
	f->writeable = !!(flags & ENV_WRITEABLE);
	f->mtd.type = MTD_ABSENT;

	if (fstat(f->fd, &f->st) == -1) {
		fprintf(stderr, "%s: stat %s: %s\n", __func__,
			name, strerror(errno));
		goto error;
	}
	if (S_ISCHR(f->st.st_mode)) {
		if (ioctl(f->fd, MEMGETINFO, &f->mtd) == -1) {
			fprintf(stderr, "%s: %s not MTD: %s\n", __func__,
				name, strerror(errno));
			goto error;
		}
		if (verbose)
			printf("%s:%s size %dMB writesize %d erasesize %dKB\n",
				__func__, f->name,
				f->mtd.size / 1024 / 1024,
				f->mtd.writesize,
				f->mtd.erasesize / 1024);
	}
	return f;
error:
	flash_close(f);
	return NULL;
}

/*
 * Load the environment from the flash device.
 * Needs to handle write block size, erase block size, skip bad NAND
 * blocks and so on, then call the deserializer
 */
flash_env_p
flash_load(
	flash_p f,
	size_t env_size,
	loff_t offset,
	int tries,
	uint16_t flags )
{
	if (f->mtd.type == MTD_ABSENT)
		f->mtd.writesize = f->mtd.erasesize = f->mtd.size = env_size;

	if (offset % f->mtd.erasesize) {
		fprintf(stderr, "%s:%s invalid unaligned load offset %d\n",
			__func__, f->name, (int)offset);
		return NULL;
	}
	flash_env_p e = calloc(1, sizeof(*e));

	e->flash = f;
	e->size = env_size;
	e->offset = offset;
	e->padded_erase = (e->size + f->mtd.erasesize - 1) &
			~(f->mtd.erasesize-1);
	e->padded_write = (e->size + f->mtd.writesize - 1) &
			~(f->mtd.writesize-1);
	if (verbose)
		printf("%s:%s env size %d, write block padded %d, "
			"erase block padded %d\n",
			__func__, f->name,
			(int)env_size, (int)e->padded_write,
			(int)e->padded_erase);
	e->loaded_size = 0;

	loff_t	cur = 0, rdpos = 0;
	char * env_flash = malloc(e->padded_erase);
	while (rdpos < e->padded_write) {
		int bad = 0;
		do {
			e->loaded_size += f->mtd.erasesize;
			if (lseek(f->fd, e->offset + cur, SEEK_SET) == -1) {
				fprintf(stderr, "%s:%s invalid offset %d: %s\n",
					__func__, f->name, (int)(e->offset + cur),
					strerror(errno));
				return e;
			}
			if (f->mtd.type == MTD_NANDFLASH) {
				bad = ioctl(f->fd, MEMGETBADBLOCK, &cur);
				if (bad)
					fprintf(stderr, "%s:%s bad block at "
						"0x%lx, skipping",
						__func__, f->name,
						(uint64_t)(e->offset + cur));
			}
			if (bad)
				cur += f->mtd.erasesize;
		} while (bad);
		size_t rd_count = rdpos + f->mtd.erasesize > e->padded_write ?
				e->padded_write - rdpos :
				f->mtd.erasesize;
		ssize_t rd = read(f->fd, env_flash + rdpos, rd_count);
		if (rd != rd_count) {
			fprintf(stderr, "%s:%s short read 0x%lx: %s\n",
				__func__, f->name, (uint64_t)(e->offset + cur),
				strerror(errno));
			return e;
		}
		cur += f->mtd.erasesize;
		rdpos += rd_count;
	}
	e->raw = env_flash;
	e->env = rawenv_load(e->raw, flags);
	switch (e->env->state) {
		case ELOAD_CRC:
			fprintf(stderr,
				"%s:%s invalid environment CRC, loaded anyway\n",
				__func__, f->name);
			break;
		case ELOAD_INIT:
			fprintf(stderr, "%s:%s environment initialized\n",
				__func__, f->name);
			break;
	}
	return e;
}

/*
 * Writes the environment back to flash. First writes it to a properly
 * sized memory block, then try to write it to flash, skipping bad erase
 * blocks on nand
 */
int
flash_save(
	flash_env_p e )
{
	flash_p f = e->flash;
	char * env_flash = malloc(e->padded_erase);

	if (rawenv_save(e->env, env_flash)) {
		fprintf(stderr,
			"%s:%s env size overflow\n",
			__func__, f->name);
		goto error;
	}
	if (e->raw && !memcmp(env_flash, e->raw, e->size)) {
		fprintf(stderr,
			"%s:%s warning: env appears unchanged\n",
			__func__, f->name);
		free(env_flash);
		return 0;
	}
	loff_t	cur = 0, wrpos = 0;
	while (wrpos < e->padded_write) {
		int bad = 0;
		struct erase_info_user erase = {
			.length = f->mtd.erasesize,
		};
		do {
			erase.start = e->offset + cur;
			if (f->mtd.type != MTD_ABSENT) {
				ioctl(f->fd, MEMUNLOCK, &erase);
				/* These do not need an explicit erase cycle */
				if (f->mtd.type != MTD_DATAFLASH)
					if (ioctl(f->fd, MEMERASE, &erase) != 0) {
						fprintf(stderr,
							"%s:%s erase error: %s\n",
							__func__, f->name,
							strerror(errno));
						bad = -1;
					}
			}
			if (!bad && lseek(f->fd, e->offset + cur, SEEK_SET) == -1) {
				fprintf(stderr, "%s:%s invalid offset %d: %s\n",
					__func__, f->name, (int)(e->offset + cur),
					strerror(errno));
				goto error;
			}
			if (!bad && f->mtd.type == MTD_NANDFLASH) {
				bad = ioctl(f->fd, MEMGETBADBLOCK, &cur);
				if (bad)
					fprintf(stderr, "%s:%s bad block at "
						"0x%lx, skipping",
						__func__, f->name,
						(uint64_t)(e->offset + cur));
			}
			if (bad)
				cur += f->mtd.erasesize;
		} while (bad);
		size_t wr_count = wrpos + f->mtd.erasesize > e->padded_write ?
				e->padded_write - wrpos :
				f->mtd.erasesize;
		ssize_t wr = write(f->fd, env_flash + wrpos, wr_count);
		if (wr != wr_count) {
			fprintf(stderr, "%s:%s write error 0x%lx: %s\n",
				__func__, f->name, (uint64_t)(e->offset + cur),
				strerror(errno));
			goto error;
		}
		if (f->mtd.type != MTD_ABSENT)
			ioctl(f->fd, MEMLOCK, &erase);

		cur += f->mtd.erasesize;
		wrpos += wr_count;
	}
	if (env_flash) {
		if (e->raw)
			free((char*)e->raw);
		e->raw = env_flash;
	}
	return 0;
error:
	free(env_flash);
	return -1;
}

static void usage(const char *p, int exit_code)
{
	printf("%s : print/dump and set u-boot environment\n"
		"   [-d <device]     : default %s\n"
		"   [-s <env size>]  : default %dKB\n"
		"   [-S|--shell]     : output as shell script\n"
		"   [-E|--export]    : -S, and also 'export' variables\n"
		"   [-i|--init]      : reset env to default [DANGEROUS]\n"
		"   [<var>=<value>]* : set <var>(s) to <value> and save\n"
		"   [<var>]*         : print <var>(s) value\n"
		"", p, CONFIG_ENV_MTD, uboot_environment_len / 1024);
	if (exit_code)
		exit(exit_code);
}

static void
print_env_as_shell(
	const char * _name,
	const char * val,
	int export)
{
	char *name = strdup(_name);
	for (char *d = name; *d; d++)
		*d = toupper(*d);
	const char * quote = NULL;
	for (const char *d = val; d && *d && !quote; d++)
		quote = *d <= ' ' ? "\"" : NULL;
	if (!quote) quote = "";
	printf("%s%s=%s%s%s\n", export ? "export " : "",
		name, quote, val ? val : "", quote);
	free(name);
}

int main(int argc, const char *argv[])
{
	const char *dev = CONFIG_ENV_MTD;
	int shellize = 0, export = 0;
	int do_set = 0, do_get = 0;
	uint16_t flags = 0;
	int parameter_start_index = 0;

	for (int i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "-d") && i < argc-1) {
			dev = argv[++i];
		} else if (!strcmp(argv[i], "-s") && i < argc-1) {
			env_size = atoi(argv[++i]);
		} else if (!strcmp(argv[i], "-v")) {
			verbose++;
		} else if (!strcmp(argv[i], "--shell") || !strcmp(argv[i], "-S")) {
			shellize++;
		} else if (!strcmp(argv[i], "--init")) {
			flags |= LOAD_FORCE_INIT|ENV_WRITEABLE;
		} else if (!strcmp(argv[i], "--export") || !strcmp(argv[i], "-E")) {
			shellize++; export++;
		} else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) {
			usage(argv[0], 0);
			exit(0);
		} else if (!strcmp(argv[i], "--")) {
			parameter_start_index = i + 1;
		} else if (argv[i][0] != '-') {
			if (!parameter_start_index)
				parameter_start_index = i;
			if (index(argv[i], '=')) {
				flags |= ENV_WRITEABLE;
				do_set++;
			} else
				do_get++;
		} else
			usage(argv[0], 1);
	}
	if (verbose)
		printf("%s env_size:%dKB do_set:%d do_get:%d shellize:%d export:%d\n",
			argv[0],
			(int)(env_size/1024), do_set, do_get, shellize, export);

	/* Open the flash device */
	flash_p flash = flash_open(dev, flags);
	if (!flash)
		exit(1);
	/* Load (or initialize) the environment */
	flash_env_p env = flash_load(flash, env_size, 0, 2, flags);
	if (!env || !env->env) {
		fprintf(stderr, "%s unable to load env from %s\n",
			argv[0], dev);
		exit(1);
	}
	if (do_set || do_get) {
		for (int i = parameter_start_index; i < argc; i++) {
			// catch teh case someone passes a '=' as parameter
			if (argv[i][0] == '-' || argv[i][0] == '=')
				continue;
			char * equ = index(argv[i], '=');
			if (equ) {
				char * name = strndup(argv[i], equ - argv[i]);
				env_set(env->env, name, equ+1);
				free(name);
			} else {
				int p = env_locate(env->env, argv[i]);
				if (p == -1) {
					if (verbose)
						fprintf(stderr,
							"%s '%s' not found\n",
							argv[0], argv[i]);
					continue;
				}
				if (shellize || export)
					print_env_as_shell(env->env->e[p].name,
						env->env->e[p].val, export);
				else if (do_get > 1)
					printf("%s=%s\n", env->env->e[p].name,
						env->env->e[p].val);
				else
					printf("%s\n",
						env->env->e[p].val);
			}
		}
	} else {
		for (int i = 0; i < env->env->count; i++) {
			if (!env->env->e[i].name)
				continue;
			if (shellize || export)
				print_env_as_shell(env->env->e[i].name,
					env->env->e[i].val, export);
			else
				printf("%s=%s\n", env->env->e[i].name,
					env->env->e[i].val);
		}
	}
	/* Possibly save the result, if it has changed */
	if (flags & ENV_WRITEABLE)
		flash_save(env);
}
