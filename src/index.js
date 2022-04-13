import assert from "assert";
import http from "http";
import { readFile } from "fs/promises";
// import pg from "pg";
import pgPromise from "pg-promise";

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
  const routes = await fetchRoutes(db);

  const server = http.createServer(async (req, res) => {
    // const client = await pgPool.connect();
    try {
      const reqUrl = new URL(req.url, "http://localhost");
      const route = routes.find((route) => route === reqUrl.pathname);
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
      const response = await db.tx(async (tx) => {
        await tx.query(
          "select set_config('sqlfe.req', '${this:raw}', true);",
          sqlfeReq
        );
        return tx.one(`select ("${route}"()).*`);
      });
      console.log({ response });
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
    console.log(`Available routes: ${routes.join(", ")}`);
  });
}

async function fetchRoutes(pgClient) {
  const routes = await pgClient.many(
    "select routine_name from information_schema.routines where routine_name like '/%'"
  );
  return routes.map(({ routine_name }) => routine_name);
}

main().catch(console.error);
