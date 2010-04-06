
# calls an optional function(s)
function optional() {
	for f in $*; do
		if declare -F $f >/dev/null; then
			$f "$@"
		fi
	done
}

function optional-one-of () {
	for f in $*; do
		if declare -F $f >/dev/null; then
			# echo optional-one-of running $f
			$f
			return
		fi
	done
}

hset() {
	local k="${2//-/}"
	eval "$1""$k"='$3'
}

hget() {
	local k="${2//-/}"
	# echo GET  $1 $2 1>&2
	eval echo '${'"$1$k"'#hash}'
}

function package() {
	export MINIFS_PACKAGE="$1"
	export PACKAGE="$1"
	export PACKAGE_DIR="$2"
	local prefix=$(hget prefix $PACKAGE)
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
	if [ -f "$BUILD"/$pack/._dist ]; then
		echo $pack was installed in staging, trying to remove
		cat "$BUILD"/$pack/._dist | \
			awk -v pp="$STAGING" \
				'{if ($2=="open" && match($3,pp)) print $3;}' | \
					xargs rm -f
	fi
	rm -rf "$BUILD"/$pack
	echo Looks like $pack was removed. good luck.
}

dump-depends() {
	(
	echo 'digraph G { rankdir=LR; node [shape=rect]; '
	local all="$PACKAGES crosstools"
	for pack in $all; do
		deps=$(hget depends $pack)
		echo \"$pack\"
		for d in $deps; do 
			echo "\"$pack\" -> \"$d\""
		done
	done	
	echo '}'
	) >minifs_deps.dot
	dot -Tpdf -ominifs_deps.pdf minifs_deps.dot
}

