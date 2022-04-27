create schema if not exists sqlfe_tests;
set search_path to sqlfe_tests, sqlfe, public;

create temporary table if not exists assert (
  expectation boolean check (expectation)
);

create temporary table if not exists assert_equals_int (
  actual int,
  expected int,
  check (actual = expected)
);

create or replace function assert_true(boolean) returns void volatile
  begin atomic
    insert into assert values ($1);
  end;

create or replace function assert_equals(int, int) returns void volatile
  begin atomic
    insert into assert_equals_int values ($1, $2);
  end;

begin;


delete from timesheet_day;
delete from consultant;
delete from project;

-- with
--   consultant as (insert into consultant (id, name) values ('RDA', '') returning *),
--   project as (insert into project (id, name) values ('eat_cakes', '') returning *),
--   timesheet_day as (
--     insert into timesheet_day
--       (consultant_id, date, project_id)
--       select consultant.id, '2019-01-01', project.id
--       from consultant, project
--       returning *
--   )
--   insert into assert_equals_int
--   select number_of_days, 1
--   from compose_project_summary(row(2019, 1))
--   where project_id = 'eat_cakes';

insert into consultant (id, name) values ('RDA', '');
insert into project (id, name) values ('eat_cakes', '');
insert into timesheet_day
  (consultant_id, date, project_id)
  values ('RDA', '2019-01-01', 'eat_cakes');

select assert_equals(number_of_days, 1)
from compose_project_summary(row(2019, 1))
where project_id = 'eat_cakes';

insert into timesheet_day
  (consultant_id, date, project_id)
  values ('RDA', '2019-01-02', 'eat_cakes');

select assert_equals(number_of_days, 2)
from compose_project_summary(row(2019, 1))
where project_id = 'eat_cakes';

insert into consultant (id, name) values ('TSP', '');
insert into timesheet_day
  (consultant_id, date, project_id)
  values ('TSP', '2019-01-02', 'eat_cakes');

select assert_equals(number_of_days, 3)
from compose_project_summary(row(2019, 1))
where project_id = 'eat_cakes';

insert into project (id, name) values ('friendship_magic', '');
update timesheet_day
  set project_id = 'friendship_magic'
  where
    consultant_id = 'RDA'
    and date = '2019-01-02';

select assert_equals(number_of_days, 2)
from compose_project_summary(row(2019, 1))
where project_id = 'eat_cakes';

select change_timesheet('RDA', row(2019, 1), 'friendship_magic');

select assert_true(is_timesheet_complete('RDA', row(2019, 1)));

rollback;
