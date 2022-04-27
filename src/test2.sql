create schema if not exists sqlfe_tests;
set search_path to sqlfe_tests, sqlfe, public;

create temporary table if not exists assert (
  expectation boolean check (expectation)
);

create temporary table if not exists assert_equals (
  actual text,
  expected text,
  check (actual = expected)
);

create or replace function assert_equals(text, text) returns void volatile
  begin atomic
    insert into assert_equals values ($1, $2);
  end;

create or replace function assert_true(boolean) returns void volatile
  begin atomic
    insert into assert values ($1);
  end;

create temporary table assert_equals_timesheet_day (
  actual timesheet_day not null,
  expected timesheet_day not null,
  check (actual = expected)
);

create function assert_equals(
  actual timesheet_day,
  expected timesheet_day
) returns void volatile
  begin atomic
    insert into assert_equals_timesheet_day
    values ($1, $2);
  end;

begin;
  -- arrange / given
  delete from timesheet_day;
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
