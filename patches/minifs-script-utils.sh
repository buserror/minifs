
function package() {
	PACKAGE="$1"
	echo "#### Building $PACKAGE"
	pushd "$BUILD/$PACKAGE"
}
function end_package() {
	#echo "#### Building $PACKAGE DONE"
	PACKAGE=""
	popd
}

function configure() {
	local turd="._conf_$PACKAGE"
	if [ ! -f $turd ]; then
		echo "#### Configuring $PACKAGE"
		rm -f $turd
		echo "$@" >$turd.log
		if "$@" >>$turd.log 2>&1 ; then
			touch $turd
		else
			echo "#### ** ERROR ** Configuring $PACKAGE"
			return 1
		fi
	fi
}
function compile() {
	local turd="._compile_$PACKAGE"
	if [ ! -f $turd -o "._conf_$PACKAGE" -nt $turd ]; then
		echo "#### Compiling $PACKAGE"
		rm -f $turd
		echo "$@" >$turd.log
		if "$@" >>$turd.log 2>&1 ; then
			touch $turd
		else
			echo "#### ** ERROR ** Compiling $PACKAGE"
			return 1
		fi
	fi
}

function install() {
	local turd="._install_$PACKAGE"
	if [ -f "._compile_$PACKAGE" ]; then
		echo "#### Installing $PACKAGE"
		rm -f $turd
		echo "$@" >$turd.log
		if "$@" >>$turd.log 2>&1 ; then
			touch $turd
		else
			echo "#### ** ERROR ** Installing $PACKAGE"
			return 1
		fi
	fi
}
