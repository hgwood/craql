docker compose exec -T postgres \
  psql \
  --username postgres \
  --single-transaction \
  --variable=ON_ERROR_STOP=on \
  --echo-errors \
  --echo-queries \
  --file=src/deploy.psql
