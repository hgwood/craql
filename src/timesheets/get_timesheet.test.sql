set search_path to "timesheets/app", "timesheets/data", "test";

begin;
  -- arrange / given
  delete from timesheet_day;
  insert into consultant values ('RDA', 'Rainbow Dash');
  insert into project values ('eat_cakes', 'Eat cakes');
  insert into timesheet_day values
    ('2019-01-01', 'RDA', 'eat_cakes'),
    ('2019-01-02', 'RDA', 'eat_cakes');
  -- act / when
  with actual as (select * from get_timesheet('RDA', row(2019, 01)))
  -- assert / then
  select
    assert_equals(actual, expected::timesheet_day)
  from actual
  full outer join (values
    ('2019-01-01', 'RDA', 'eat_cakes'),
    ('2019-01-02', 'RDA', 'eat_cakes')
  ) as expected on actual = expected::timesheet_day;
rollback;
