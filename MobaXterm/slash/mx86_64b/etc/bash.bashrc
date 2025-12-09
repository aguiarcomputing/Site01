if [ "$SHELL" != "/bin/bash.exe" ]; then
  export SHELL="/bin/bash.exe"
  export FIRSTTIME=true
  . /etc/profile
fi
