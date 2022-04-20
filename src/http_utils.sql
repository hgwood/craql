create function ok(body json = json_build_object()) returns http_response immutable
  return row(200, json_build_object('Content-Type', 'application/json'), body);

create function bad_request() returns http_response immutable
  return row(400, json_build_object('Content-Type', 'application/json'), json_build_object());
