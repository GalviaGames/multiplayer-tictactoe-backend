#! /bin/sh

/nakama/nakama migrate up --database.address ${PGUSER}@${PGHOST}:${PGPORT} && exec /nakama/nakama --name nakama1 --database.address ${PGUSER}@${PGHOST}:${PGPORT} --runtime.path /nakama/data/modules