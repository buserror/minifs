#!/bin/bash

echo \#if 0
uboot_binary=$1

echo // u-boot filename: $uboot_binary

sym=($(objdump -t $uboot_binary | grep default_environment))

echo // symbol section ${sym[3]} addr ${sym[0]} size ${sym[4]}

section=($(objdump -h $uboot_binary |grep ${sym[3]}))

echo // section base ${section[3]} offset ${section[5]}

sym_addr=$((0x${sym[0]}))
sym_size=$((0x${sym[4]}))
section_addr=$((0x${section[3]}))

offset_in_section=$((sym_addr - section_addr))
section_file_offset=$((0x${section[5]}))

offset_in_file=$((section_file_offset + offset_in_section))

dd if=$uboot_binary of=uboot_environment bs=1 \
	skip=$offset_in_file count=$sym_size >/dev/null 2>&1 || exit 1

hexdump -C uboot_environment
echo \#endif
xxd -i uboot_environment | sed 's/^unsigned/static const unsigned/'

rm -f uboot_environment

exit 0

# $ objdump -t u-boot|grep default_environment
# 04018d01 g     O .rodata        000000ec default_environment
# $ objdump -h u-boot|grep .rodata
#   1 .rodata       00008b3b  04016598  04016598  0001e598  2**3
