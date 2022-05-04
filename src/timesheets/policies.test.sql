set search_path to "timesheets/app", "timesheets/data", "test", "public";

begin;
  -- arrange / given
  delete from timesheet_day;
  delete from consultant;
  delete from project;
  insert into project values ('eat_cakes', 'Eat cakes');
  insert into consultant values ('RDA', 'Rainbow Dash');
  insert into consultant values ('AJA', 'Apple Jack');
  insert into timesheet_day values
    ('2019-01-01', 'RDA', 'eat_cakes'),
    ('2019-01-02', 'AJA', 'eat_cakes');
  -- act / when
  select set_config('sqlfe.req', '{ "headers": { "x-sqlfe-user-id": "RDA" } }', true);
  set role to consultant;
  with actual as (select * from get_timesheet(null, row(2019, 1)))
  -- assert / then
  select
    assert_equals(actual::"timesheets/data".timesheet_day, expected::"timesheets/data".timesheet_day)
  from actual
  full outer join (values
    ('2019-01-01', 'RDA', 'eat_cakes')
  ) as expected on actual = expected::"timesheets/data".timesheet_day;
rollback;
