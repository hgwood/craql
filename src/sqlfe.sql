create type http_request as (
  url text,
  pathname text,
  query json,
  method text,
  headers json,
  body json
);

create type http_response as (
  status_code int,
  headers json,
  body json
);
