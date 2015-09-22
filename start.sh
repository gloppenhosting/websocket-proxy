#!/bin/bash -eux

[ -d "$RUNDIR" ] || mkdir "$RUNDIR"
chown haproxy:haproxy "$RUNDIR"
chmod 2775 "$RUNDIR"

export ETCD_PORT=${ETCD_PORT:-4001}
export HOST_IP=${HOST_IP:-172.17.42.1}
export ETCD=127.0.0.1:4001

echo "[haproxy-confd] booting container. ETCD: $ETCD"

# Loop until confd has updated the haproxy config
until confd -onetime -node $ETCD -config-file /etc/confd/conf.d/haproxy.toml; do
  echo "[haproxy-confd] waiting for confd to refresh haproxy.cfg"
  sleep 5
done

# Run confd in the background to watch the upstream servers
confd -interval 10 -node $ETCD -config-file /etc/confd/conf.d/haproxy.toml >> /var/log/output.log 2>&1 &

tail -f /var/log/output.log
