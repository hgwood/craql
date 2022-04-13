drop function if exists "/timesheets"();
drop type if exists http_response;

create type http_response as (
  status_code int,
  headers json,
  body json
);

create function "/timesheets"() returns http_response
  return row(
      200,
      '{"Content-Type": "application/json"}'::json,
      (select json_build_object('days', json_object_agg(date, project_id)) from timesheet_day where consultant_id = (current_setting('sqlfe.req')::json)->'query'->>'consultant')
  );

create table if not exists consultant (
  id char(3) primary key,
  name text not null
);

create table if not exists project (
  id text primary key,
  name text not null
);

create table if not exists timesheet_day (
  date date not null,
  consultant_id char(3) not null references consultant (id),
  project_id text not null references project (id),
  primary key (consultant_id, date)
);

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
    ('2022-04-01', 'TSP', 'friendship_magic'),
    ('2022-04-02', 'TSP', 'celestia')
  on conflict (date, consultant_id)
    do update set project_id = excluded.project_id;
