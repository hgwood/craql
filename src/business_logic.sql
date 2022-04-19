drop type if exists year_month cascade;
create type year_month as (year int, month int);

drop function if exists year_month_of(date) cascade;
create function year_month_of(date) returns year_month
  return row(
    extract(year from $1),
    extract(month from $1)
  );

drop function if exists first_day_of(year_month) cascade;
create function first_day_of(year_month) returns date immutable
  return make_date($1.year, $1.month, 1);

drop function if exists last_day_of(year_month) cascade;
create function last_day_of(year_month) returns date immutable
  return first_day_of($1) + (interval '1 month - 1 day');

drop function if exists number_of_days_in_month(year_month) cascade;
create function number_of_days_in_month(year_month) returns int immutable
  return extract(days from last_day_of($1));

create function get_timesheet(timesheet_day.consultant_id%type, year_month) returns setof timesheet_day stable
  begin atomic
    select *
    from timesheet_day
    where
      consultant_id = $1
      and year_month_of(date) = $2;
  end;

create function is_timesheet_complete(timesheet_day.consultant_id%type, year_month) returns boolean stable
  begin atomic
    select count(*) = number_of_days_in_month($2)
    from timesheet_day
    where
      consultant_id = $1
      and year_month_of(date) = $2;
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

drop function if exists change_timesheet(timesheet_day.consultant_id%type, year_month, timesheet_day.project_id%type);
create or replace function change_timesheet(timesheet_day.consultant_id%type, year_month, timesheet_day.project_id%type) returns timesheet_day
  begin atomic
    insert into timesheet_day
      (consultant_id, date, project_id)
      select
        $1,
        date::date,
        $3
      from
        generate_series(
          first_day_of($2)::timestamp,
          last_day_of($2)::timestamp,
          interval '1 day'
        ) date
      on conflict (consultant_id, date) do update set project_id = excluded.project_id
      returning *;
  end;

create function compose_project_summary(year_month) returns table (project_id project.id%type, number_of_days int) stable
  begin atomic
    select
      project_id,
      count(*)
    from timesheet_day
    where
      extract(year from date) = $1.year
      and extract(month from date) = $1.month
    group by project_id;
  end;
