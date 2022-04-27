create view http_endpoint (function_name, method, path) as (
  select
    routine_name,
    endpoint_info[1],
    endpoint_info[2]
  from
    information_schema.routines,
    regexp_match(routine_name, '^(GET|POST) (/.*)$') as endpoint_info
  where endpoint_info is not null
);
