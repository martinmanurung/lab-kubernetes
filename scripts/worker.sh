#!/bin/bash
set -euxo pipefail

JOIN_SCRIPT="/vagrant/shared/join.sh"

echo "=== Menunggu file ${JOIN_SCRIPT} dari control-plane ==="
while [ ! -s "${JOIN_SCRIPT}" ]; do
  echo "Menunggu token join dari control-plane..."
  sleep 5
done

echo "=== Token join ditemukan! Bergabung ke kluster... ==="
bash "${JOIN_SCRIPT}"

echo "=== Berhasil bergabung ke kluster Kubernetes ==="
