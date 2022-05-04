for each in src/*/migrations/*.sql; do
  echo -n $each,%;
  cat $each | tr '\n' ' ';
  echo %;
done
