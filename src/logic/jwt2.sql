create extension pgcrypto;

create function encode_base64_url(content bytea) returns text as $$
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

create function parse_jwt(jwt text) returns json immutable
  return (
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
  );
