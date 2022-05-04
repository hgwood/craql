create function is_timesheet_complete(
  timesheet_day.consultant_id%type,
  year_month
) returns boolean stable
  begin atomic
    select count(*) = number_of_days_in_month($2)
    from timesheet_day
    where
      consultant_id = $1
      and year_month_of(day) = $2;
  end;
