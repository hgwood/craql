-- data schema

create table if not exists consultant (
  id char(3) primary key,
  name text not null
);

create table if not exists project (
  id text primary key,
  name text not null
);

drop table timesheet_day cascade;
create table if not exists timesheet_day (
  date date not null,
  consultant_id char(3) not null references consultant (id),
  project_id text not null references project (id),
  primary key (consultant_id, date)
);

-- sample data

insert into
  consultant (id, name)
  values
    ('RDA', 'Rainbow Dash'),
    ('TSP', 'Twilight Sparkles'),
    ('AJA', 'Applejack'),
    ('PPI', 'Pinkie Pie')
  on conflict (id)
    do update set name = excluded.name;

insert into
  project (id, name)
  values
    ('friendship_magic', 'Etudier la magie de l''amitié'),
    ('celestia', 'S''entretenir avec Célestia'),
    ('apples', 'Récolter les pommes'),
    ('eat_cakes', 'Manger des gâteaux'),
    ('clean_pastry_shop', 'Nettoyer la pâtisserie'),
    ('make_cakes', 'Faire des gâteaux'),
    ('race', 'Faire la course')
  on conflict (id)
    do update set name = excluded.name;

insert into
  timesheet_day (date, consultant_id, project_id)
  values
    ('2022-04-01', 'RDA', 'eat_cakes'),
    ('2022-04-02', 'RDA', 'race'),
    ('2022-03-01', 'TSP', 'friendship_magic'),
    ('2022-03-02', 'TSP', 'celestia'),
    ('2022-04-01', 'TSP', 'friendship_magic'),
    ('2022-04-02', 'TSP', 'celestia')
  on conflict (date, consultant_id)
    do update set project_id = excluded.project_id;

-- business logic

drop function if exists compose_iso_month(date) cascade;
create function compose_iso_month(date) returns text immutable
  return to_char($1, 'YYYY-MM');

drop function if exists compose_start_of_iso_month(text) cascade;
create function compose_start_of_iso_month(iso_month text) returns date immutable
  return to_date(iso_month, 'YYYY-MM');

create function get_timesheet(timesheet_day.consultant_id%type, iso_month text) returns setof timesheet_day stable
  begin atomic
    select *
    from timesheet_day
    where
      consultant_id = $1
      and compose_iso_month(date) = iso_month;
  end;

drop function if exists change_timesheet(timesheet_day.consultant_id%type, timesheet_day.date%type, timesheet_day.project_id%type);
create or replace function change_timesheet(timesheet_day.consultant_id%type, timesheet_day.date%type, timesheet_day.project_id%type) returns timesheet_day
  begin atomic
    insert into timesheet_day
      (consultant_id, date, project_id)
      values ($1, $2, $3)
      on conflict (consultant_id, date) do update set project_id = excluded.project_id
      returning *;
  end;

drop function if exists change_timesheet(timesheet_day.consultant_id%type, iso_month text, timesheet_day.project_id%type);
create or replace function change_timesheet(timesheet_day.consultant_id%type, iso_month text, timesheet_day.project_id%type) returns timesheet_day
  begin atomic
    insert into timesheet_day
      (consultant_id, date, project_id)
      select
        $1,
        date::date,
        $3
      from
        generate_series(
          compose_start_of_iso_month(iso_month)::timestamp,
          compose_start_of_iso_month(iso_month)::timestamp + (interval '1 month' - interval '1 day'),
          interval '1 day'
        ) date
      on conflict (consultant_id, date) do update set project_id = excluded.project_id
      returning *;
  end;

create function compose_project_summary(iso_month text) returns table (project_id project.id%type, number_of_days int) stable
  begin atomic
    select
      project_id,
      count(*)
    from timesheet_day
    where compose_iso_month(date) = iso_month
    group by project_id;
  end;


-- http utils

drop type if exists http_response cascade;
create type http_response as (
  status_code int,
  headers json,
  body json
);

drop function if exists ok(http_response) cascade;
create function ok(body json = json_build_object()) returns http_response immutable
  return row(200, json_build_object('Content-Type', 'application/json'), body);

drop function if exists bad_request(http_response) cascade;
create function bad_request() returns http_response immutable
  return row(400, json_build_object('Content-Type', 'application/json'), json_build_object());

drop function if exists req() cascade;
create function req() returns json stable
  return current_setting('sqlfe.req')::json;

drop function if exists req_query_param(text);
create function req_query_param(name text) returns text stable
  return req()->'query'->>name;

drop function if exists req_body();
create function req_body() returns json stable
  return req()->'body';

-- http endpoints

drop function if exists "GET /timesheets"();
create function "GET /timesheets"() returns http_response stable
  return
    case
      when
        req_query_param('consultant') is not null
        and req_query_param('month') is not null
      then
        ok((
          select
            json_build_object(
              'days',
              coalesce(json_object_agg(date, project_id), '{}'::json)
            )
          from get_timesheet(
            req_query_param('consultant'),
            req_query_param('month')
          )
        ))
      else
        bad_request()
    end;

drop function if exists "POST /timesheets"();
create or replace function "POST /timesheets"() returns http_response volatile
  return
    case
      when
        req_body()->>'consultant' is not null
        and req_body()->>'date' is not null
        and req_body()->>'project' is not null
      then
        ok(
          to_json(
            change_timesheet(
              req_body()->>'consultant',
              (req_body()->>'date')::date,
              req_body()->>'project'
            )
          )
        )
      when
        req_body()->>'consultant' is not null
        and req_body()->>'month' is not null
        and req_body()->>'project' is not null
      then
        ok(
          to_json(
            change_timesheet(
              req_body()->>'consultant',
              req_body()->>'month',
              req_body()->>'project'
            )
          )
        )
      else
        bad_request()
    end;

drop function if exists "GET /projects"();
create or replace function "GET /projects"() returns http_response volatile
  return
    case
      when
        req_query_param('month') is not null
      then
        ok((
          select
            json_object_agg(project_id, number_of_days)
          from
            compose_project_summary(
              req_query_param('month')
            )
        ))
      else
        bad_request()
    end;
