create function fill_timesheet(
  timesheet_day.consultant_id%type,
  timesheet_day.day%type,
  timesheet_day.project_id%type
) returns timesheet_day
  begin atomic
    insert into timesheet_day
      (consultant_id, day, project_id)
      values ($1, $2, $3)
      on conflict (consultant_id, day)
        do update set project_id = excluded.project_id
      returning *;
  end;

create function "POST /timesheets"(req http_request) returns http_response volatile
  return
    case
      when
        req.body->>'consultant' is not null
        and req.body->>'date' is not null
        and req.body->>'project' is not null
      then
        ok(
          to_json(
            fill_timesheet(
              req.body->>'consultant',
              (req.body->>'date')::date,
              req.body->>'project'
            )
          )
        )
      else
        bad_request()
    end;
