# craql

A small example app to show how to program business web app back-ends in SQL
with PostgreSQL.

## What is the app about?

It's an app to manage timesheets. Basically, you set who works on what and when.
The people who work on stuff are called consultants. The stuff they work on is
called projects. One consultant works on one project at a time, and can only
work on one project each day.

## Why SQL?

The challenge of building business apps is to model the business data and
processes, and to keep up with evolution of those. They are information
processing apps. So it might be a good idea to use a high-level,
data-manipulation-specific programming language. SQL is also very often already
part of the stack anyway!

> ⚠ I'm referring to SQL, not PL/SQL or PL/pgSQL.

## How does it work?

- Tables are defined using SQL migration files, as usual for a typical business
  app.
- Business operations are written as SQL functions.
- HTTP endpoints are also written as SQL functions. Since the database does talk
  HTTP, these are not actual endpoints, only functions that accept an HTTP
  request-like data structure and return an HTTP response-like data structure.
- A tiny, generic Node.js web server exposes those SQL functions as actual HTTP
  endpoints.

## How to run it?

You'll need: Docker, Node.js,
[psql](https://www.postgresql.org/docs/current/app-psql.html). To run API tests
you'll also need [hurl](https://hurl.dev/).

- Copy `.env.example` to `.env`.
- Run the database using `docker compose up -d`.
- Deploy the app to the database using `sh scripts/deploy.sh`.
- Optional: insert some data using `sh scripts/insert_sample_data.sh`.
- Install dependencies for the web server using `npm install`.
- Start the web server using `npm start`.
- Call the HTTP endpoints using your favorite HTTP client. Take a look at the
  API tests in `test/api` to see what endpoints are available and how to use
  them. They are written in [Hurl](https://hurl.dev/).

## How to run the tests?

- For API tests: `sh scripts/run_api_tests.sh`.
- For SQL unit tests: `sh scripts/run_sql_tests.sh`.

## How do SQL unit tests work?

SQL has no assert function. However, something similar can be achieved using
table constraints. See the `assert_true` function in `test/sql/assert_true.sql`.
See also `test/sql/assert_equal_timesheet_day.sql` for a more complex assertion
that compares two rows of a table.

## What are those `.psql` files?

These files are meant to be run using
[psql](https://www.postgresql.org/docs/current/app-psql.html) (`psql
--file=...`). They contain plain SQL along with psql meta-commands.

## How is code deployed to the database?

Defining code entities (functions, types, etc.) in conventional languages is
declarative. This is possible because compilers are stateless one-off processes
which start from scratch every time. This is different in SQL. The database is
both the compiler and the program, and it is always running. Code entities are
defined imperatively. In addition, some code entities, like tables, contain data
and cannot be dropped and recreated once they have been used in production.

In typical apps, the solution to this problem is to use a migration tool that
applies incremental changes to the database. Of course, it would be possible to
use this kind of tool for an app entirely written in SQL, but it wouldn't work
well with usual version control tools like git.

Consider a SQL function that has been defined in a migration file and deployed
to production. When the code of this function must be inevitably patched down
the line, a new migration file must be written with the new version of the
function. Since git sees this as a new file, it cannot help with diffing the two
versions of the function and that makes it hard to tell what's been changed.

In craql, I've tried to use the right tool for the right job: for tables and
entities on which tables depend, I use a migration tool. Other entities are
dropped and recreated every time the code is deployed.

There is still a big challenge to consider: the order of the dropping and
creating. Consider a function A that calls a function B. SQL doesn't allow B to
be dropped if A exists nor can A be created before B.

My solution is to have that order be explicit in the source code.
`src/create.psql` is a script that creates all stateless code entities.
`src/drop.psql` does the reverse. When deploying, `src/drop.psql` is run first,
then migrations are applied, then `src/create.psql` is run.

## What migration tool is used?

A custom one I wrote in SQL, obviously ;). It loads the migration files into a
temporary table in the database, then computes (in SQL) which ones have not been
already applied, then applies those (using `\gexec` from psql). It also checks
that migration file corresponding to migrations that have already been applied
in the past have not changed since. See `scripts/migrate.psql`.

## Does this use standard SQL?

No. This uses SQL only supported by PostgreSQL 14 and later.
