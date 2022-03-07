import fs from "fs/promises";
import http from "http";
import pg from "pg";
import yaml from "yaml";

async function main() {
  const yml = (await fs.readFile("sqlfe.yml")).toString();
  const sqlfe = yaml.parse(yml);
  const pgPool = new pg.Pool();

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
        const queryResult = await pgPool.query(route.query);
        res.writeHead(200);
        res.write(JSON.stringify(queryResult.rows));
        res.end();
      } catch (err) {
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
