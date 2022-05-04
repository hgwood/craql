sh scripts/psql.sh \
  --single-transaction \
  --variable=ON_ERROR_STOP=on \
  --echo-errors \
  --echo-queries \
  --file=test/sql/run.psql
