drop schema if exists "timesheets/app" cascade;
drop policy if exists consultant_only_sees_their_own_timesheet on timesheet_day;
select exists(select from pg_roles where rolname = 'consultant') as consultant_exists;
\gset
\if :consultant_exists
  revoke all on timesheet_day from consultant;
  drop role consultant;
\endif
