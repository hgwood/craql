import fs from "fs/promises";
import http from "http";
import pg from "pg";
import yaml from "yaml";
import pgPromise from "pg-promise";
import streamConsumers from "stream/consumers";
import _ from "lodash";

const dbConnection = {
  host: process.env.PGHOST,
  port: process.env.PGPORT,
  database: process.env.PGDATABASE,
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
};

const pgp = pgPromise();

async function main() {
  const yml = (await fs.readFile("sqlfe.yml")).toString();
  const sqlfe = yaml.parse(yml);
  // const pgPool = new pg.Pool();
  const db = pgp(dbConnection);

  const server = http
    .createServer(async (req, res) => {
      try {
        const route = sqlfe.routes[req.url];
        if (!route) {
          res.writeHead(404);
          res.end();
          return;
        }
        if (!route.query) {
          res.writeHead(500);
          res.end();
          return;
        }
        let body;
        try {
          body = await streamConsumers.json(req);
        } catch (err) {
          res.writeHead(400);
          res.end(err.message);
          return;
        }
        console.log(route, body);
        let queryResult;
        try {
          queryResult = await db.result(route.query, body);
          // queryResult = await pgPool.query(formattedQuery);
        } catch (err) {
          const [, propertyName] =
            err.message.match(/Property '(.*?)' doesn't exist./) || [];
          if (propertyName) {
            console.debug(400, err.message);
            res.writeHead(400);
            res.end(err.message);
            return;
          }
          const [, contraintName] =
            err.message.match(
              /duplicate key value violates unique constraint "(.*?)"/
            ) || [];
          if (contraintName) {
            console.debug(409, err.message);
            res.writeHead(409);
            res.end(err.message);
            return;
          }
          throw err;
        }
        console.log({ queryResult });
        let responseBody = queryResult?.rows || [];
        if (route.select) {
          responseBody = responseBody.map((row) => row[route.select]);
        }
        responseBody = responseBody.map((row) => {
          const result = {};
          Object.entries(row).forEach(([key, value]) => {
            _.set(result, key, value);
          });
          return result;
        });
        if (route.arity === 1) {
          responseBody = responseBody?.[0] || {};
        }
        console.log({ responseBody });
        res.writeHead(200);
        res.write(JSON.stringify(responseBody));
        res.end();
      } catch (err) {
        console.error(err);
        res.writeHead(500);
        res.end();
        return;
      }
    })
    .listen(8788, () => {
      console.log("Listening on port 8788");
    });

  process.on("SIGINT", async () => {
    console.log("SIGINT received");
    await pgPool.end();
    server.close();
  });
}

main().catch(console.error);
