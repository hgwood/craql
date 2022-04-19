alter table timesheet_day enable row level security;

grant select on timesheet_day to consultant;

drop policy if exists consultants_only_see_their_own_timesheet on timesheet_day;
create policy consultants_only_see_their_own_timesheet on timesheet_day
  as permissive
  for all
  to consultant
  using (consultant_id = (current_setting('sqlfe.req', true)::json)->'headers'->>'x-sqlfe-user-id');
