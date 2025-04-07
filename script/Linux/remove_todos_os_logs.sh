#!/bin/bash
if [ "$EUID" -ne 0 ]; then
  echo "Execute como root com sudo."
  exit 1
fi
echo "Removendo todos os logs em /var/log..."
find /var/log -type f -delete
echo "Logs removidos com sucesso!"
