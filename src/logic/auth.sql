create function logic.req() returns json as $$
  select current_setting('sqlfe.context')::json
$$ language sql stable;


create function logic.req_token() returns text as $$
  select
    substring(req()->'headers'->>'authorization' from 7)
$$ language sql stable;

create function logic.req_user() returns bigint as $$
  select extract_user_id_from_jwt(req_token())
$$ language sql stable;
