create type year_month as (year int, month int);

create function year_month_of(date) returns year_month
  return row(
    extract(year from $1),
    extract(month from $1)
  );

create function first_day_of(year_month) returns date immutable
  return make_date($1.year, $1.month, 1);

create function last_day_of(year_month) returns date immutable
  return first_day_of($1) + (interval '1 month - 1 day');

create function number_of_days_in_month(year_month) returns int immutable
  return extract(days from last_day_of($1));
