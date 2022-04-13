drop function if exists "/timesheets"();
drop type if exists http_response;

create type http_response as (
  status_code int,
  headers json,
  body json
);

create function "/timesheets"() returns http_response
  return row(
    200,
    '{"Content-Type": "application/json"}',
    '{"days": { "2022-04-01": "eat_cakes", "2022-04-02": "race" }}'
  );
