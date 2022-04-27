create type year_month as (year int, month int);

create function year_month_of(date) returns year_month
  return row(
    extract(year from $1),
    extract(month from $1)
  );
