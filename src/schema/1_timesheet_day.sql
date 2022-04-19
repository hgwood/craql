
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
