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
  return to_char($1, 'IYYY-MM');

create function get_timesheet(consultant.id%type, iso_month text) returns setof timesheet_day
  begin atomic
    select *
    from timesheet_day
    where
      consultant_id = $1
      and compose_iso_month(date) = $2;
  end;

-- http utils

drop type if exists http_response cascade;
create type http_response as (
  status_code int,
  headers json,
  body json
);

drop function if exists req() cascade;
create function req() returns json return current_setting('sqlfe.req')::json;

drop function if exists req_query_param(text);
create function req_query_param(name text) returns text
  return req()->'query'->>name;

-- http endpoints

drop function if exists "/timesheets"();
create function "/timesheets"() returns http_response
  return
    case
      when
        req_query_param('consultant') is not null
        and req_query_param('month') is not null
      then
        row(
          200,
          '{"Content-Type": "application/json"}'::json,
          (
            select
              json_build_object(
                'days',
                coalesce(json_object_agg(date, project_id), '{}'::json)
              )
            from get_timesheet(
              req_query_param('consultant'),
              req_query_param('month')
            )
          )
        )::http_response
      else
        row(
          400,
          '{"Content-Type": "application/json"}'::json,
          '{}'::json
        )::http_response
    end;
