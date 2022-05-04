import http from "http";
import pgPromise from "pg-promise";
import streamConsumers from "stream/consumers";

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
  const routes = await fetchAvailableEndpoints(db);

  const server = http.createServer(async (req, res) => {
    try {
      const reqUrl = new URL(req.url, "http://localhost");
      const route = routes.find(
        ({ method, path }) => path === reqUrl.pathname && method === req.method
      );
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
      const craqlReq = {
        body,
        headers: req.headers,
        query: Object.fromEntries(reqUrl.searchParams.entries()),
      };
      const response = await db.tx(
        {
          mode: new pgPromise.txMode.TransactionMode({
            readOnly: route.method === "GET",
          }),
        },
        async (tx) => {
          await tx.any(`set search_path to "timesheets/app";`);
          await tx.query(
            "select set_config('craql.req', '${this:raw}', true);",
            craqlReq
          );
          if (req.headers["x-craql-role"]) {
            await tx.query(`set local role "${req.headers["x-craql-role"]}"`);
          }
          const query = pgp.as.format(
            `select ($(functionName:name)(row($(url), $(pathname), $(query:json), $(method), $(headers:json), $(body:json))::http.http_request)).*`,
            {
              functionName: route.functionName,
              url: reqUrl.toString(),
              pathname: reqUrl.pathname,
              query: craqlReq.query,
              method: req.method,
              headers: craqlReq.headers,
              body: craqlReq.body,
            }
          );
          return tx.one(query);
        }
      );
      res.writeHead(response.status_code, response.headers);
      res.end(JSON.stringify(response.body));
    } catch (err) {
      console.error(err);
      res.writeHead(500);
      res.end();
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

async function fetchAvailableEndpoints(pgClient) {
  const routes = await pgClient.many("select * from http.http_endpoint");
  return routes.map(({ function_name: functionName, method, path }) => ({
    functionName,
    method,
    path,
  }));
}

main().catch(console.error);
