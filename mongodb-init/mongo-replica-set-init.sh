#!/usr/bin/env bash
set -euo pipefail

KEYFILE="/etc/mongo-keyfile"
DBPATH="/data/db"
REPLSET_NAME="rs0"
ADMIN_USER="inventorydba"
ADMIN_PWD="password"
APP_DB="rawsrcdb"

log(){ echo "[$(date -Is)] $*"; }

wait_for_mongo() {
  local tries=0 max=60
  until mongosh --quiet --eval "db.adminCommand({ ping: 1 })" >/dev/null 2>&1; do
    tries=$((tries+1))
    if [ $tries -gt $max ]; then
      log "ERROR: mongod did not respond after $max seconds"
      return 1
    fi
    sleep 1
  done
}

is_repl_initialized() {
  mongosh --quiet --eval "try { rs.status().ok } catch(e) { print('NO_RS'); }" 2>/dev/null | grep -E '^1$' >/dev/null 2>&1
}

admin_user_exists() {
  mongosh --quiet --eval "JSON.stringify(db.getSiblingDB('admin').getUser('${ADMIN_USER}'))" 2>/dev/null | grep -v "null" >/dev/null 2>&1
}

start_mongod_bg_noauth_nokey() {
  log "Starting mongod (initial) WITHOUT auth/without keyfile ..."
  mongod --replSet "$REPLSET_NAME" --bind_ip_all --dbpath "$DBPATH" --quiet &
  BG_PID=$!
  log "mongod PID=$BG_PID"
  wait_for_mongo
}

stop_pid() {
  local pid="$1"
  if ps -p "$pid" >/dev/null 2>&1; then
    log "Stopping mongod PID $pid ..."
    kill -TERM "$pid"
    for i in {1..30}; do
      if ! ps -p "$pid" >/dev/null 2>&1; then break; fi
      sleep 1
    done
  fi
}

log "Init script start"

# If already initialized and user present -> exec mongod with keyfile/auth (final service)
if is_repl_initialized && admin_user_exists; then
  log "Replica set + admin user present -> exec mongod WITH auth (foreground)"
  if [ -f "$KEYFILE" ]; then
    exec mongod --replSet "$REPLSET_NAME" --bind_ip_all --dbpath "$DBPATH" --keyFile "$KEYFILE" --auth
  else
    exec mongod --replSet "$REPLSET_NAME" --bind_ip_all --dbpath "$DBPATH" --auth
  fi
fi

# Start initial mongod WITHOUT keyfile and WITHOUT auth (important)
start_mongod_bg_noauth_nokey
INIT_PID=${BG_PID:-0}

# Initiate replset if needed
if ! is_repl_initialized; then
  log "Initiating replica set..."
  mongosh --quiet <<'EOF'
rs.initiate({_id: "rs0", members: [{ _id: 0, host: "127.0.0.1:27017" }]});
EOF
  # wait until primary
  for i in {1..30}; do
    IS_PRIMARY=$(mongosh --quiet --eval "rs.isMaster().ismaster" 2>/dev/null || echo "false")
    if [ "$IS_PRIMARY" = "true" ]; then
      log "Node is primary"
      break
    fi
    sleep 1
  done
fi

# Create admin user BEFORE enabling auth
if ! admin_user_exists; then
  log "Creating admin user '${ADMIN_USER}'..."
  mongosh --quiet <<MONGO_EOF
use admin;
db.createUser({
  user: "${ADMIN_USER}",
  pwd: "${ADMIN_PWD}",
  roles: [
    { role: "root", db: "admin" },
    { role: "readWrite", db: "${APP_DB}" }
  ]
});
MONGO_EOF
  log "Admin user created"
else
  log "Admin user exists, skipping creation"
fi

# Optionally ensure app collections
mongosh --quiet <<MONGO_EOF
db = db.getSiblingDB("${APP_DB}");
db.createCollection("rawdata");
db.createCollection("inventory");
db.createCollection("brand");
db.createCollection("customer");
MONGO_EOF

# Stop initial mongod and restart with keyfile+auth
stop_pid "${INIT_PID}"
sleep 2

log "Starting mongod WITH keyFile and --auth (foreground)"
if [ -f "$KEYFILE" ]; then
  chmod 600 "$KEYFILE" || true
  exec mongod --replSet "$REPLSET_NAME" --bind_ip_all --dbpath "$DBPATH" --keyFile "$KEYFILE" --auth
else
  log "Keyfile not present; still starting with --auth (not recommended)"
  exec mongod --replSet "$REPLSET_NAME" --bind_ip_all --dbpath "$DBPATH" --auth
fi
