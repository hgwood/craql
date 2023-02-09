sh scripts/psql.sh \
  --username postgres \
  --single-transaction \
  --variable=ON_ERROR_STOP=on \
  --echo-errors \
  --quiet \
  --file=scripts/deploy.psql
