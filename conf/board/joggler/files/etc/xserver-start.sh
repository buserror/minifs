
Xfbdev :0 -mouse mouse -keybd keyboard -dpi 100 -rgba rgb
export WEBKIT_DEBUG=1
GtkLauncher --display :0 http://www.tvguide.co.uk/tv_channel_streams.asp\?c=16 &


X :0 -dpi 100 -ac -config xorg.conf.new &