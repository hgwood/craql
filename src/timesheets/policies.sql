create role consultant nologin;
grant consultant to postgres;
grant all on timesheet_day to consultant;
grant usage on schema http to consultant;
grant usage on schema "timesheets/data" to consultant;
grant usage on schema "timesheets/app" to consultant;
alter table timesheet_day enable row level security;
create policy consultant_only_sees_their_own_timesheet on timesheet_day
  as permissive
  for all
  to consultant
  using (consultant_id = (current_setting('sqlfe.req', true)::json)->'headers'->>'x-sqlfe-user-id');
