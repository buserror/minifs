

if [ "$CONFIG_MODULES" != "" ]; then
	PACKAGES+=" linux-modules"
fi

PACKAGES+=" linux-bare"
