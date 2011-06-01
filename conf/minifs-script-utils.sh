
# check for dependencies
function check_host_commands() {
	local allok=1
	#echo "*** Checking for $NEEDED_HOST_COMMANDS"
	for de in $NEEDED_HOST_COMMANDS ; do
		if ! path=$(which "$de"); then
			echo "#### Missing '$de' host command"
			allok=0
		fi
	done
	if [ "$allok" -eq "0" ]; then
		echo "##### Please install the missing host commands"
		exit 1
	fi
}

function hostcheck_commands() {
	for name in $*; do 
		local cmd=$(which $name)
		if [ ! -x "$cmd" ]; then
			echo "### ERROR $PACKAGE needs $name"
			HOSTCHECK_FAILED=1
			break;
		fi
	done
}

# split the MINIFS_PATH evn and return all existing directories
# also adding the first parameter to the path
minifs_path_split() {
	for pd in $(echo "$MINIFS_PATH"| tr ":" "\n") ; do
		if [ -d "$pd/$1" ]; then
			echo "$pd/$1"
		fi
	done
}

# calls an optional function(s)
function optional() {
	for f in $*; do
		if declare -F $f >/dev/null; then
			$f "$@"
		fi
	done
}

function optional_one_of () {
	for f in $*; do
		if declare -F $f >/dev/null; then
			# echo optional-one-of running $f
			$f
			return
		fi
	done
}

function hset() {
	local ka="${1//-/}"
	local kb="${2//-/}"
	eval "$ka$kb"='$3'
}

function hget() {
	local ka="${1//-/}"
	local kb="${2//-/}"
	# echo GET  $1 $2 1>&2
	eval echo '${'"$ka$kb"'#hash}'
}

function package() {
	export MINIFS_PACKAGE="$1"
	export PACKAGE="$1"
	export PACKAGE_DIR="$2"
	local prefix=$(hget $PACKAGE prefix)
	export PACKAGE_PREFIX=${prefix:-/usr}
	pushd "$BUILD/$PACKAGE_DIR" >/dev/null
}
function end_package() {
	#echo "#### Building $PACKAGE DONE"
	PACKAGE=""
	LOGFILE="._stray.log"
	popd  >/dev/null
}

function configure() {
	local turd="._conf_$PACKAGE"
	LOGFILE="$turd.log"
	if [ ! -f $turd ]; then
		echo "     Configuring $PACKAGE"
		rm -f $turd
		echo "$@" >$LOGFILE
		if "$@" >>$LOGFILE 2>&1 ; then
			touch $turd
		else
			echo "#### ** ERROR ** Configuring $PACKAGE"
			echo "     Check $BUILD/$PACKAGE/$LOGFILE"
			exit 1
		fi
	fi
}

function compile() {
	local turd="._compile_$PACKAGE"
	LOGFILE="$turd.log"
	if [ ! -f $turd -o "._conf_$PACKAGE" -nt $turd ]; then
		echo "     Compiling $PACKAGE"
		rm -f $turd
		echo "$@" >$LOGFILE
		if "$@" >>$LOGFILE 2>&1 ; then
			touch $turd
		else
			echo "#### ** ERROR ** Compiling $PACKAGE"
			echo "     Check $BUILD/$PACKAGE/$LOGFILE"
			exit 1
		fi
	fi
}

function log_install() {
	local turd="._install_$PACKAGE"
	LOGFILE="$turd.log"
	if [ ! -f $turd -o "._compile_$PACKAGE" -nt $turd ]; then
		echo "     Installing $PACKAGE"
		rm -f $turd
		echo "$@" >$LOGFILE
		if "$@" >>$LOGFILE 2>&1 ; then
			touch $turd
		else
			echo "#### ** ERROR ** Installing $PACKAGE"
			echo "     Check $BUILD/$PACKAGE/$LOGFILE"
			exit 1
		fi
	fi
}

function deploy() {
	local turd="._deploy_$PACKAGE"
	LOGFILE="$turd.log"
	if [ -f "._install_$PACKAGE" ]; then
		echo "     Deploying $PACKAGE"
		rm -f $turd
		echo "$@" >$LOGFILE
		if "$@" >>$LOGFILE 2>&1 ; then
			touch $turd
		else
			echo "#### ** ERROR ** Deploying $PACKAGE"
			echo "     Check $BUILD/$PACKAGE/$LOGFILE"
			exit 1
		fi
	fi
}

function remove_package() {
	pack=$1
	if [ ! -d "$BUILD"/$pack ]; then
		echo Not removing $pack - was not installed anyway
		return
	fi
	if [ -f "$BUILD/$pack/._dist_$pack.log" ]; then
		echo $pack was installed in staging, trying to remove
		cat "$BUILD/$pack/._dist_$pack.log" | \
			awk -v pp="$STAGING" \
				'{if ($2=="open" && match($3,pp)) print $3;}' | \
					xargs rm -f
	fi
	rm -rf "$BUILD"/$pack
	echo Looks like $pack was removed. good luck.
}

function get_installed_binaries() {
	if [ -f "$BUILD/$pack/._dist_$PACKAGE.log" ]; then
		cat "$BUILD/$pack/._dist_$PACKAGE.log" | \
			awk -v pp="^$STAGING.*/s?bin/" \
				'{if ($2=="open" && match($3,pp)) print $3;}' 
	fi
}

function get_installed_etc() {
	if [ -f "$BUILD/$pack/._dist_$PACKAGE.log" ]; then
		cat "$BUILD/$pack/._dist_$PACKAGE.log" | \
			awk -v pp="^$STAGING.*/etc/" \
				'{if ($2=="open" && match($3,pp)) print $3;}' 
	fi
}

function deploy_staging_path() {
	(cd "$STAGING_USR/$1"; tar cf - .)|(mkdir -p "$ROOTFS/$1"; cd "$ROOTFS/$1"; tar xf -)
}

function dump_depends() {
	(
	echo 'digraph G { rankdir=LR; node [shape=rect]; '
	local all="$PACKAGES crosstools"
	for pack in $all; do
		deps=$(hget $pack depends)
		echo \"$pack\"
		for d in $deps; do 
			echo "\"$pack\" -> \"$d\""
		done
	done	
	echo '}'
	) >minifs_deps.dot
	dot -Tpdf -ominifs_deps.pdf minifs_deps.dot
}

