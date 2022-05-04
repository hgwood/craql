set search_path to "timesheets/app", "timesheets/data", "test";

begin;
  -- arrange / given
  delete from timesheet_day;
  delete from consultant;
  delete from project;
  insert into project values ('eat_cakes', 'Eat cakes');
  insert into consultant values ('RDA', 'Rainbow Dash');
  -- act / when
  select fill_timesheet('RDA', row(2019, 1), 'eat_cakes');
  with actual as (select * from get_timesheet('RDA', row(2019, 1)))
  -- assert / then
  select
    assert_equals(actual, expected::timesheet_day)
  from actual
  full outer join (values
    ('2019-01-01', 'RDA', 'eat_cakes'),
    ('2019-01-02', 'RDA', 'eat_cakes'),
    ('2019-01-03', 'RDA', 'eat_cakes'),
    ('2019-01-04', 'RDA', 'eat_cakes'),
    ('2019-01-05', 'RDA', 'eat_cakes'),
    ('2019-01-06', 'RDA', 'eat_cakes'),
    ('2019-01-07', 'RDA', 'eat_cakes'),
    ('2019-01-08', 'RDA', 'eat_cakes'),
    ('2019-01-09', 'RDA', 'eat_cakes'),
    ('2019-01-10', 'RDA', 'eat_cakes'),
    ('2019-01-11', 'RDA', 'eat_cakes'),
    ('2019-01-12', 'RDA', 'eat_cakes'),
    ('2019-01-13', 'RDA', 'eat_cakes'),
    ('2019-01-14', 'RDA', 'eat_cakes'),
    ('2019-01-15', 'RDA', 'eat_cakes'),
    ('2019-01-16', 'RDA', 'eat_cakes'),
    ('2019-01-17', 'RDA', 'eat_cakes'),
    ('2019-01-18', 'RDA', 'eat_cakes'),
    ('2019-01-19', 'RDA', 'eat_cakes'),
    ('2019-01-20', 'RDA', 'eat_cakes'),
    ('2019-01-21', 'RDA', 'eat_cakes'),
    ('2019-01-22', 'RDA', 'eat_cakes'),
    ('2019-01-23', 'RDA', 'eat_cakes'),
    ('2019-01-24', 'RDA', 'eat_cakes'),
    ('2019-01-25', 'RDA', 'eat_cakes'),
    ('2019-01-26', 'RDA', 'eat_cakes'),
    ('2019-01-27', 'RDA', 'eat_cakes'),
    ('2019-01-28', 'RDA', 'eat_cakes'),
    ('2019-01-29', 'RDA', 'eat_cakes'),
    ('2019-01-30', 'RDA', 'eat_cakes'),
    ('2019-01-31', 'RDA', 'eat_cakes')
  ) as expected on actual = expected::timesheet_day;
rollback;
