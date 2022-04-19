drop type if exists http_request cascade;
create type http_request as (
  url text,
  pathname text,
  query json,
  method text,
  headers json,
  body json
);

drop type if exists http_response cascade;
create type http_response as (
  status_code int,
  headers json,
  body json
);

drop function if exists ok(http_response) cascade;
create function ok(body json = json_build_object()) returns http_response immutable
  return row(200, json_build_object('Content-Type', 'application/json'), body);

drop function if exists bad_request(http_response) cascade;
create function bad_request() returns http_response immutable
  return row(400, json_build_object('Content-Type', 'application/json'), json_build_object());
