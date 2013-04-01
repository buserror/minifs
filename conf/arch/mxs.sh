

. "$CONF_BASE"/arch/armv5.sh

MINIFS_BOARD_ROLE+=" mxs"

mxs-set-versions() {
	hset linux version "3.9-rc4"
}
