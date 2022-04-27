
create extension if not exists pgcrypto;

create function logic.encode_base64_url(content bytea) returns text as $$
  select
    rtrim(
      replace(
        replace(
          translate( -- see https://stackoverflow.com/questions/53710378/stop-postgresql-from-spliting-values-in-multiple-lines
            encode(content, 'base64'),
            E'\n',
            ''
          ),
          '+',
          '-'
        ),
        '/',
        '_'
      ),
      '='
    )
$$ language sql immutable;

create function decode_base64_url(content text) returns text as $$
  select convert_from(
    decode(
      rpad(
        replace(
          replace(
            content,
            '_',
            '/'
          ),
          '-',
          '+'
        ),
        ((div(char_length(content), 4) + 1) * 4)::int,
        '='
      ),
      'base64'
    ),
    'UTF8'
  )
$$ language sql immutable;

create function logic.json_stringify(content json) returns text as $$
  select regexp_replace(content::text, '\s+', '', 'g')
$$ language sql immutable;

create function logic.now_epoch() returns bigint as $$
  select extract(epoch from date_trunc('second', current_timestamp))
$$ language sql stable;

create function logic.craft_jwt(
  user_id bigint
) returns text as $$
  select
    concat(
      jwt.payload_to_sign,
      '.',
      encode_base64_url(
        hmac(
          jwt.payload_to_sign,
          'fake_secret_please_change_this__',
          'sha512'
        )
      )
    )
  from (
    select
      concat(
        encode_base64_url(
          json_stringify(json_build_object('alg', 'HS512', 'typ', 'JWT'))::bytea
        ),
        '.',
        encode_base64_url(
          json_stringify(
            json_build_object(
              'iss',
              'https://github.com/hgwood/realworld-conduit-sqlfe',
              'sub',
              user_id::text,
              'iat',
              now_epoch(),
              'exp',
              now_epoch() + 86400,
              'jti',
              gen_random_uuid()::text
            )
          )::bytea
        )
      ) as payload_to_sign
  ) as jwt
$$ language sql stable;

create function logic.parse_jwt(jwt text) returns json as $$
  select decode_base64_url(split_part(jwt, '.', 2))::json
  from (select jwt) as jwt
  where
    encode_base64_url(
      hmac(
        concat(
          split_part(jwt, '.', 1),
          '.',
          split_part(jwt, '.', 2)
        ),
        'fake_secret_please_change_this__',
        'sha512'
      )
    ) = split_part(jwt, '.', 3)
$$ language sql immutable;

create function logic.extract_user_id_from_jwt(jwt text) returns bigint as $$
  select (parse_jwt(jwt)->>'sub')::bigint
$$ language sql immutable;
