-- jwt

drop function if exists extract_user_id_from_jwt(text);
drop function if exists parse_jwt(text);
drop function if exists craft_jwt(bigint);
drop function if exists now_epoch();
drop function if exists json_stringify(json);
drop function if exists decode_base64_url(text);
drop function if exists encode_base64_url(bytea);

create extension if not exists pgcrypto;

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

create function json_stringify(content json) returns text as $$
  select regexp_replace(content::text, '\s+', '', 'g')
$$ language sql immutable;

create function now_epoch() returns bigint as $$
  select extract(epoch from date_trunc('second', current_timestamp))
$$ language sql stable;

create function craft_jwt(
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

create function parse_jwt(jwt text) returns json as $$
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

create function extract_user_id_from_jwt(jwt text) returns bigint as $$
  select (parse_jwt(jwt)->>'sub')::bigint
$$ language sql immutable;

-- auth

drop function if exists req_user;
drop function if exists req_token;
drop function if exists req;

create function req() returns json as $$
  select current_setting('sqlfe.context')::json
$$ language sql stable;


create function req_token() returns text as $$
  select
    substring(req()->'headers'->>'authorization' from 7)
$$ language sql stable;

create function req_user() returns bigint as $$
  select extract_user_id_from_jwt(req_token())
$$ language sql stable;

-- app

drop function if exists "/articles/feed";
drop function if exists "/articles";
drop function if exists as_json(article_for_user);
drop function if exists articles_for_user_as_json;
drop function if exists articles_for_user;
drop type article_for_user;
drop view if exists article_favorite_count;
drop table if exists favorite;
drop table if exists follow;
drop table if exists article;
drop table if exists "user";

create table "user" (
  id bigint primary key generated always as identity,
  name text not null unique,
  email text not null unique,
  password text not null,
  image text,
  bio text
);

create table article (
  id bigint primary key generated always as identity,
  slug text not null unique,
  title text not null,
  description text not null,
  body text not null,
  created_at timestamp not null default current_timestamp,
  updated_at timestamp not null default current_timestamp,
  author_id bigint not null references "user" (id)
);

create table follow (
  follower_id bigint not null references "user" (id),
  following_id bigint not null references "user" (id),
  primary key (follower_id, following_id)
);

create table favorite (
  user_id bigint not null references "user" (id),
  article_id bigint not null references article (id),
  primary key (user_id, article_id)
);

create view article_favorite_count as (
  select
    article_id,
    count(*) as count,
    array_agg(user_id) as favoriters
  from favorite
  group by article_id
);

create type article_for_user as (
  title text,
  slug text,
  description text,
  body text,
  created_at timestamp,
  updated_at timestamp,
  favorites_count bigint,
  favorited boolean,
  author_bio text,
  author_image text,
  author_name text,
  author_followed boolean
);

create function articles_for_user (
  requesting_user_id bigint,
  filter_by_author_name text,
  filter_by_favoriter_name text,
  "offset" bigint,
  "limit" bigint
)
  returns setof article_for_user
  as $$
    select
      article.title,
      article.slug,
      article.description,
      article.body,
      article.created_at,
      article.updated_at,
      coalesce(article_favorite_count.count, 0),
      favorite.user_id is not null,
      author.bio,
      author.image,
      author.name,
      follow.follower_id is not null
    from article
    join "user" as author on author.id = article.author_id
    left join article_favorite_count on article.id = article_favorite_count.article_id
    left join "user" as requesting_user on requesting_user.id = requesting_user_id
    left join follow on
      follow.following_id = author.id
      and follow.follower_id = "requesting_user".id
    left join favorite on
      favorite.article_id = article.id
      and favorite.user_id = "requesting_user".id
    where
      (author.name = filter_by_author_name or filter_by_author_name is null)
      and (
        (
          select id
          from "user"
          where name = filter_by_favoriter_name
        ) = any(article_favorite_count.favoriters)
        or filter_by_favoriter_name is null
      )
    order by article.created_at desc
    offset ("offset")
    limit ("limit")
  $$
  language sql
  stable;

create function as_json (
  article article_for_user
)
  returns json
  as $$
    select
      json_build_object(
        'title',
        article.title,
        'slug',
        article.slug,
        'description',
        article.description,
        'body',
        article.body,
        'createdAt',
        article.created_at,
        'updatedAt',
        article.updated_at,
        'favoritesCount',
        article.favorites_count,
        'favorited',
        article.favorited,
        'author',
        json_build_object(
          'bio',
          article.author_bio,
          'image',
          article.author_image,
          'username',
          article.author_name,
          'followed',
          article.author_followed
        )
      )
  $$
  language sql
  stable;

create function articles_for_user_as_json (
  articles article_for_user[]
)
  returns json
  as $$
    select
      json_build_object(
        'articles',
        coalesce(
          json_agg(
            (article).as_json
          ),
          json_build_array()
        ),
        'articlesCount',
        count(*)
      )
    from unnest(articles) as article
  $$
  language sql
  stable;

create function "/articles" (
  requesting_user_email text,
  filter_by_author_name text,
  filter_by_favoriter_name text,
  "offset" bigint,
  "limit" bigint
)
  returns json
  as $$
    select
      articles_for_user_as_json(array_agg(article))
    from articles_for_user(
      (select id from "user" where email = requesting_user_email),
      filter_by_author_name,
      filter_by_favoriter_name,
      "offset",
      "limit"
    ) as article
  $$
  language sql
  stable;

create function "/articles/feed" (
  requesting_user_email text,
  "offset" bigint,
  "limit" bigint
)
  returns json
  as $$
    select
      articles_for_user_as_json(array_agg(article))
    from articles_for_user(
      (select id from "user" where email = requesting_user_email),
      null,
      null,
      "offset",
      "limit"
    ) as article
    where article.author_followed = true
  $$
  language sql
  stable;

-- data

delete from article;
delete from "user";

insert into "user"
  (name, email, password, image, bio)
  values
  ('Alice', 'alice@example.com', 'password', null, null),
  ('Bob', 'bob@example.com', 'password', null, null),
  ('Claire', 'claire@example.com', 'password', null, null);

insert into article
  (slug, title, description, body, author_id)
  values
  (
    'hello-world',
    'Hello World',
    'This is the first article',
    'This is the body of the first article',
    (select id from "user" where name = 'Alice')
  ),
  (
    'hello-universe',
    'Hello Universe',
    'This is the second article',
    'This is the body of the second article',
    (select id from "user" where name = 'Claire')
  );

insert into favorite
  (user_id, article_id)
  values
  (
    (select id from "user" where name = 'Alice'),
    (select id from article where slug = 'hello-world')
  ),
  (
    (select id from "user" where name = 'Bob'),
    (select id from article where slug = 'hello-world')
  );

insert into follow
  (follower_id, following_id)
  values
  (
    (select id from "user" where name = 'Alice'),
    (select id from "user" where name = 'Bob')
  ),
  (
    (select id from "user" where name = 'Bob'),
    (select id from "user" where name = 'Alice')
  );
