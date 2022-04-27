docker compose exec postgres psql --username postgres --single-transaction --variable=ON_ERROR_STOP=on --echo-errors --echo-queries --file=test/run.psql
