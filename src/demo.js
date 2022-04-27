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
  const db = pgp(dbConnection);
  await db.any("set search_path to sqlfe, public;");
  const httpEndpoints = await db.many("select * from http_endpoint");
  const server = http.createServer(async (req, res) => {
    const reqUrl = new URL(req.url, "http://localhost");
    const matchingEndpoint = httpEndpoints.find(({ method, path }) => {
      return method === req.method && path === reqUrl.pathname;
    });
    const dbResponse = await db.one(
      `select ($(functionName:name)(row($(url), $(pathname), $(query:json), $(method), $(headers:json), $(body:json)))).*`,
      {
        functionName: matchingEndpoint.function_name,
        url: req.url,
        pathname: reqUrl.pathname,
        query: Object.fromEntries(reqUrl.searchParams.entries()),
        method: req.method,
        headers: req.headers,
        body: req.method === "POST" ? await streamConsumers.json(req) : null,
      }
    );
    res.writeHead(dbResponse.status_code, dbResponse.headers);
    res.end(JSON.stringify(dbResponse.body));
  });
  server.listen(3210, () => {
    console.log(`Listening on port 3210`);
    console.log(
      `Available routes: ${httpEndpoints
        .map(({ function_name }) => function_name)
        .join(", ")}`
    );
  });
}

main().catch(console.error);
