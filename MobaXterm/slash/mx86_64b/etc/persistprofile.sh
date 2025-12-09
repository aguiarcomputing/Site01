[ -e "/bin/mount.exe" ] && MOUNT=/bin/mount.exe || MOUNT="/bin/toybox.exe mount"
eval $MOUNT '$SYMLINKS/usr' "/usr" 2>/dev/null
eval $MOUNT '$SYMLINKS/bin' "/bin" 2>/dev/null
eval $MOUNT '$SYMLINKS/bin' "/usr/bin" 2>/dev/null
eval $MOUNT '$SYMLINKS/lib' "/lib" 2>/dev/null
eval $MOUNT '$SYMLINKS/lib' "/usr/lib" 2>/dev/null
eval $MOUNT '$SYMLINKS/sbin' "/sbin" 2>/dev/null
eval $MOUNT '$SYMLINKS/etc' "/etc" 2>/dev/null
eval $MOUNT '$SYMLINKS/opt' "/opt" 2>/dev/null
eval $MOUNT '$SYMLINKS/src' "/src" 2>/dev/null
eval $MOUNT '$SYMLINKS/var' "/var" 2>/dev/null
eval $MOUNT '$SYMLINKS/tmp' "/tmp" 2>/dev/null
$MOUNT -a
. /etc/profile

