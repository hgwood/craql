sh scripts/psql.sh \
  --username postgres \
  --single-transaction \
  --variable=ON_ERROR_STOP=on \
  --echo-errors \
  --echo-queries \
  --file=scripts/deploy.psql
