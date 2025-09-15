FILE=/tmp/pool_nodes.csv
psql -h localhost -p 9999 -c "SHOW POOL_NODES;" --csv > $FILE
# extract information
yq -p csv '.[]|.status' $FILE

psql -c "select datname, backend_app, session_start, session, query from pg_stat_activity" --csv > $FILE
