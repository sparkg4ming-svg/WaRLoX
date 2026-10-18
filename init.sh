#!/bin/sh
# CraZy X4G init (oneshot): prepare everything before services start.
export PYTHONUNBUFFERED=1
exec 2>&1   # everything to normal log (Railway shows stderr in red)
ulimit -n "$(ulimit -Hn 2>/dev/null || echo 65535)" 2>/dev/null || ulimit -n 65535 2>/dev/null || true
mkdir -p /run/CraZy /etc/x-ui /var/log/x-ui
for d in ngx-body ngx-proxy ngx-fcgi ngx-uwsgi ngx-scgi; do mkdir -p "/tmp/$d"; chmod 1777 "/tmp/$d"; done
i=0
until python3 /opt/CraZy/bootstrap.py; do
  i=$((i+1))
  if [ "$i" -ge 3 ]; then echo "[CraZy] bootstrap failed 3 times"; exit 1; fi
  echo "[CraZy] bootstrap retry $i"; sleep 3
done
if ! nginx -t -c /run/CraZy/nginx.conf; then
  echo "[CraZy] nginx rejected the tuned config -> switching to safe config"
  python3 /opt/CraZy/render.py --safe || exit 1
  nginx -t -c /run/CraZy/nginx.conf || { echo "[CraZy] nginx config invalid"; exit 1; }
fi
exit 0
