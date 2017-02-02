#!/bin/bash

echo "============================================================================"
echo "Menseting database pycsw"
cd /opt/pycsw-2.0/pycsw/
pycsw-admin.py -c setup_db -f default.cfg

echo "============================================================================"
echo "Selesai. Untuk konfigurasi selanjutnya lihat manual"
echo "============================================================================"
