create function get_timesheet(
  timesheet_day.consultant_id%type,
  year_month
) returns setof timesheet_day stable
  begin atomic
    select *
    from timesheet_day
    where
      consultant_id = $1
      and year_month_of(day) = $2;
  end;

create function parse_iso_month(iso_month text) returns year_month immutable
  begin atomic
    select row(
      extract(year from first_day_of_month),
      extract(month from first_day_of_month)
    )
    from to_date($1, 'YYYY-MM') as first_day_of_month;
  end;

create function "GET /timesheets"(
  req http_request
) returns http_response stable
  return
    case
      when
        req.query->>'month' is not null
        and req.query->>'consultant' is not null
      then
        ok((
          select coalesce(json_object_agg(day, project_id), '{}')
          from get_timesheet(
            req.query->>'consultant',
            parse_iso_month(req.query->>'month')
          )
        ))
      else
        bad_request()
    end;
