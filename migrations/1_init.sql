drop view if exists feed;
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
    count(*) as count
  from favorite
  group by article_id
);

create view feed as (
  select
    article.slug,
    article.description,
    article.body,
    article.created_at,
    article.updated_at,
    favorite.user_id is not null as favorited,
    article_favorite_count.count as favorites_count,
    author.id
  from article
  join "user" as author on author.id = article.author_id
  left join favorite on favorite.article_id = article.id
  left join article_favorite_count on article_favorite_count.article_id = article.id
);
