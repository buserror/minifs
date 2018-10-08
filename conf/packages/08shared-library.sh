

PACKAGES+=" rootfs-create"
hset rootfs-create url "none"
hset rootfs-create phases "deploy"
hset rootfs-create dir "."

#######################################################################
## Create base rootfs tree
#######################################################################
deploy-rootfs-create() {
	echo "    Creating rootfs"
	mkdir -p "$ROOTFS"
	rm -rf "$ROOTFS"/*
	for pd in "$CONF_BASE/rootfs-base" $(minifs_path_split "rootfs"); do
		if [ -d "$pd" ]; then
			rsync -a "$pd/" "$ROOTFS/"
		fi
	done
}
