FILE=/tmp/activities.csv
psql -c "select datname, application_name, backend_start, state, query from pg_stat_activity order by datname" -d postgres --csv |tee $FILE

FILE=/tmp/database.csv
psql -c "select datname, numbackends, sessions, session_time from pg_stat_database order by datname" -d postgres --csv |tee $FILE
# total number of connections
query() {
    QUERY = $1
    FILE = $2
    psql - <<EOF
    \a
    \f ','
    \pset footer off
    $QUERY;
    EOF >> $file

}
query "select datname from pg_stat_database" '/tmp/test'
