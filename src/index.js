import { inspect } from "util";
import http from "http";
import { readFile } from "fs/promises";
// import pg from "pg";
import pgPromise from "pg-promise";
import streamConsumers from "stream/consumers";
import assert from "assert";

const dbConnection = {
  host: process.env.PGHOST,
  port: process.env.PGPORT,
  database: process.env.PGDATABASE,
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
};

const pgp = pgPromise();
pgp.pg.types.setTypeParser(20, BigInt); // see https://github.com/vitaly-t/pg-promise/wiki/BigInt

async function main() {
  const port = process.env.PORT || 8788;
  const db = pgp(dbConnection);
  // const pgPool = new pg.Pool();
  await db.any((await readFile("./src/app.sql")).toString());
  try {
    await db.any((await readFile("./src/test.sql")).toString());
  } catch (err) {
    if (err.constraint === "assert_equals_int_check") {
      const [, actual, expected] =
        err.detail?.match(/^Failing row contains \((.*), (.*)\)\.$/) || [];
      console.log({ err, actual, expected });
      assert.equal(actual, expected);
    } else {
      throw err;
    }
  }
  const routes = await fetchRoutes(db);

  const server = http.createServer(async (req, res) => {
    // const client = await pgPool.connect();
    try {
      const reqUrl = new URL(req.url, "http://localhost");
      const route = routes.find(
        ({ method, path }) => path === reqUrl.pathname && method === req.method
      );
      console.log({ route, method: req.method, path: reqUrl.pathname });
      if (!route) {
        res.writeHead(404);
        res.end();
        return;
      }
      let body;
      if (
        req.headers["content-type"] === "application/json" &&
        req.method === "POST"
      ) {
        try {
          body = await streamConsumers.json(req);
        } catch (err) {
          console.error(err);
          res.writeHead(400);
          res.end(err.message);
          return;
        }
      }
      const sqlfeReq = {
        body,
        headers: req.headers,
        query: Object.fromEntries(reqUrl.searchParams.entries()),
      };
      console.log({ sqlfeReq });
      const response = await db.tx(async (tx) => {
        await tx.query(
          "select set_config('sqlfe.req', '${this:raw}', true);",
          sqlfeReq
        );
        console.log(`Running`, route.functionName);
        return tx.one(`select ("${route.functionName}"()).*`);
      });
      console.log(inspect({ response }, { depth: null, colors: true }));
      res.writeHead(response.status_code, response.headers);
      res.end(JSON.stringify(response.body));
    } catch (err) {
      console.error(err);
      res.writeHead(500);
      res.end();
    } finally {
      // client.release();
    }
  });
  server.listen(port, () => {
    console.log(`Listening on port ${port}`);
    console.log(
      `Available routes: ${routes
        .map(({ functionName }) => functionName)
        .join(", ")}`
    );
  });
}

async function fetchRoutes(pgClient) {
  const routes = await pgClient.many(
    "select routine_name from information_schema.routines where routine_name similar to '(GET|POST) /%'"
  );
  return routes
    .map(({ routine_name }) => routine_name.match(/^(GET|POST) (\/.*)$/))
    .map(([functionName, method, path]) => ({ functionName, method, path }));
}

main().catch(console.error);
