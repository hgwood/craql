create role consultant nologin;
grant consultant to postgres;
grant all on timesheet_day to consultant;
alter table timesheet_day enable row level security;
create policy consultant_only_sees_their_own_timesheet on timesheet_day
  as permissive
  for all
  to consultant
  using (consultant_id = (current_setting('sqlfe.req', true)::json)->'headers'->>'x-sqlfe-user-id');
