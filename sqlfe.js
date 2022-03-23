import fs from "fs/promises";
import http from "http";
import pg from "pg";
import yaml from "yaml";
import pgPromise from "pg-promise";
import streamConsumers from "stream/consumers";
import _ from "lodash";
import mustache from "mustache";

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
  const yml = (await fs.readFile("sqlfe.yml")).toString();
  const sqlfe = yaml.parse(yml);
  // const pgPool = new pg.Pool();
  const db = pgp(dbConnection);

  const server = http
    .createServer(async (req, res) => {
      const reqUrl = new URL(req.url, "http://localhost");
      try {
        const route = sqlfe.routes[reqUrl.pathname];
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
        if (
          req.headers["content-type"] === "application/json" &&
          req.method === "POST" &&
          !route.ignoreBody
        ) {
          try {
            body = await streamConsumers.json(req);
          } catch (err) {
            res.writeHead(400);
            res.end(err.message);
            return;
          }
        }
        console.log({ route, body });
        let queryResult;
        try {
          const templateVars = {
            body,
            headers: req.headers,
            query: Object.fromEntries(reqUrl.searchParams.entries()),
          };
          const mustacheQuery = mustache.render(route.query, templateVars);
          console.log({ mustacheQuery });
          queryResult = await db.tx(async (tx) => {
            await tx.query(
              "select set_config('sqlfe.context', '${this:raw}', true);",
              templateVars
            );
            return tx.result(
              pgp.as.format(mustacheQuery, templateVars, { def: () => null })
            );
          });
          // queryResult = await db.result(mustacheQuery, templateVars);
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
        let responseBody = queryResult?.rows || [];
        // console.log({ queryResult });
        if (route.select) {
          responseBody = responseBody.map((row) => row[route.select]);
        }
        let needsMerging = false;
        responseBody = responseBody.map((row, index) => {
          const result = {};
          Object.entries(row).forEach(([key, value]) => {
            const indexAwareKey = key.replaceAll("[#]", `[${index}]`);
            needsMerging = needsMerging || indexAwareKey !== key;
            _.set(result, indexAwareKey, value);
          });
          return result;
        });
        if (needsMerging) {
          responseBody = _.merge(...responseBody);
        }
        if (route.arity === 1) {
          responseBody = responseBody?.[0];
          if (!responseBody) {
            res.writeHead(404);
            res.end("Not found");
            return;
          }
        }
        if (route.count) {
          responseBody[route.count] = queryResult.rowCount;
        }
        console.log({ responseBody });
        res.writeHead(200);
        res.write(pgp.as.json(responseBody, true));
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
