set -e
sh scripts/deploy.sh
sh scripts/run_sql_tests.sh
sh scripts/run_api_tests.sh
