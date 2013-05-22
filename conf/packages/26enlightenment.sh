
PACKAGES+=" libeina"
hset libeina url "http://download.enlightenment.org/releases/eina-1.7.7.tar.gz"

PACKAGES+=" libeet"
hset libeet url "http://download.enlightenment.org/releases/eet-1.7.7.tar.gz"
hset libeet depends "libeina"

PACKAGES+=" libevas"
hset libevas url "http://download.enlightenment.org/releases/evas-1.7.7.tar.gz"
hset libevas depends "libpixman libeet"
hset libevas optional "libjpeg libpng libpixman libharfbuzz"

PACKAGES+=" libeio"
hset libeio url "http://download.enlightenment.org/releases/eet-1.7.7.tar.gz"
hset libeio depends "libeet"

PACKAGES+=" libecore"
hset libecore url "http://download.enlightenment.org/releases/ecore-1.7.7.tar.gz"
hset libecore depends "libeio libevas"


