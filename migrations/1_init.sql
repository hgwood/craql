drop function if exists "/articles";
drop function if exists as_json(article_for_user);
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
      json_build_object(
        'articles',
        json_agg(
          (article).as_json
        ),
        'articlesCount',
        count(*)
      )
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
