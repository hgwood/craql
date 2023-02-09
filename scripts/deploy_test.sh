set -e
echo '*** Deploy ***'
sh scripts/deploy.sh
echo '*** Tests ***'
sh scripts/run_sql_tests.sh
