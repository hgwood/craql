create table assert_equals_timesheet_day (
  actual timesheet_day not null,
  expected timesheet_day not null,
  check (actual = expected)
);

create function assert_equals(
  actual timesheet_day,
  expected timesheet_day
) returns void volatile
  begin atomic
    insert into assert_equals_timesheet_day
    values ($1, $2);
  end;
