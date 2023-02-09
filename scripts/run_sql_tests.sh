sh scripts/psql.sh \
  --variable=ON_ERROR_STOP=on \
  --echo-errors \
  --quiet \
  --file=test/sql/run.psql \
  --output test/sql/logs.txt
