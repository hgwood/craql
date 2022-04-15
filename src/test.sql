
create temporary table if not exists assert (
  expectation boolean check (expectation)
);

create temporary table if not exists assert_equals_int (
  actual int,
  expected int,
  check (actual = expected)
);

begin;

delete from timesheet_day;
delete from consultant;
delete from project;

insert into consultant (id, name) values ('RDA', '');
insert into project (id, name) values ('eat_cakes', '');
insert into timesheet_day
  (consultant_id, date, project_id)
  values ('RDA', '2019-01-01', 'eat_cakes');

insert into assert_equals_int
  select number_of_days, 1
  from compose_project_summary('2019-01')
  where project_id = 'eat_cakes';

insert into timesheet_day
  (consultant_id, date, project_id)
  values ('RDA', '2019-01-02', 'eat_cakes');

insert into assert_equals_int
  select number_of_days, 2
  from compose_project_summary('2019-01')
  where project_id = 'eat_cakes';

insert into consultant (id, name) values ('TSP', '');
insert into timesheet_day
  (consultant_id, date, project_id)
  values ('TSP', '2019-01-02', 'eat_cakes');

insert into assert_equals_int
  select number_of_days, 3
  from compose_project_summary('2019-01')
  where project_id = 'eat_cakes';

insert into project (id, name) values ('friendship_magic', '');
update timesheet_day
  set project_id = 'friendship_magic'
  where
    consultant_id = 'RDA'
    and date = '2019-01-02';

insert into assert_equals_int
  select number_of_days, 2
  from compose_project_summary('2019-01')
  where project_id = 'eat_cakes';

rollback;
