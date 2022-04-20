-- format converters

create function compose_iso_month(date) returns text immutable
  return to_char($1, 'YYYY-MM');

create function parse_iso_month(iso_month text) returns year_month immutable
  begin atomic
    select row(
      extract(year from first_day_of_month),
      extract(month from first_day_of_month)
    )
    from to_date($1, 'YYYY-MM') as first_day_of_month;
  end;

-- http endpoints

create function "GET /timesheets"(req http_request) returns http_response stable
  return
    case
      when
        req.query->>'month' is not null
        and (
          req.headers->>'x-sqlfe-user-id' is not null
          or req.query->>'consultant' is not null
        )
      then
        ok((
          with
            timesheet (days, complete) as (
              select
                coalesce(json_object_agg(date, project_id), json_build_object()),
                -- NOTE: 'complete' is a single value so it is either true for all
                -- rows or false for all rows but it needs to be wrapped in
                -- aggregation function anyway
                coalesce(every(complete), false)
              from
                coalesce(req.query->>'consultant', req.headers->>'x-sqlfe-user-id') as consultant_id,
                is_timesheet_complete(consultant_id, parse_iso_month(req.query->>'month')) as complete,
                get_timesheet(consultant_id, parse_iso_month(req.query->>'month'))
            )
          select to_json(timesheet.*) from timesheet
        ))
      else
        bad_request()
    end;

create or replace function "POST /timesheets"(req http_request) returns http_response volatile
  return
    case
      when
        req.body->>'consultant' is not null
        and req.body->>'date' is not null
        and req.body->>'project' is not null
      then
        ok(
          to_json(
            change_timesheet(
              req.body->>'consultant',
              (req.body->>'date')::date,
              req.body->>'project'
            )
          )
        )
      when
        req.body->>'consultant' is not null
        and req.body->>'month' is not null
        and req.body->>'project' is not null
      then
        ok(
          to_json(
            change_timesheet(
              req.body->>'consultant',
              parse_iso_month(req.body->>'month'),
              req.body->>'project'
            )
          )
        )
      else
        bad_request()
    end;

create or replace function "GET /projects"(req http_request) returns http_response volatile
  return
    case
      when
        req.query->>'month' is not null
      then
        ok((
          select
            json_object_agg(project_id, number_of_days)
          from
            compose_project_summary(
              parse_iso_month(req.query->>'month')
            )
        ))
      else
        bad_request()
    end;

create function get_endpoints() returns table (function_name text, method text, path text) stable
  begin atomic
    select
      routine_name,
      endpoint_info[1],
      endpoint_info[2]
    from
      information_schema.routines,
      regexp_match(routine_name, '^(GET|POST) (/.*)$') as endpoint_info
    where endpoint_info is not null;
  end;
