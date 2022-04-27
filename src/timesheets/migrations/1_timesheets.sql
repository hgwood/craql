create table if not exists consultant (
  id text primary key,
  name text not null
);

create table if not exists project (
  id text primary key,
  name text not null
);

create table if not exists timesheet_day (
  day date not null,
  consultant_id text not null references consultant (id),
  project_id text references project (id),
  primary key (consultant_id, day)
);
