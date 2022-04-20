import { readFile } from "fs/promises";
import pg from "pg";
import postgresMigrations from "postgres-migrations";

async function main(argv) {
  const [migrationFolderPath, ...logicFilePaths] = argv;
  await migrate(migrationFolderPath);
  await upgrade(logicFilePaths);
}

async function migrate(migrationFolderPath) {
  const client = new pg.Client();
  await client.connect();
  try {
    const migrations = await postgresMigrations.migrate(
      { client },
      migrationFolderPath
    );
    console.log({ migrations: migrations.map(({ fileName }) => fileName) });
  } finally {
    await client.end();
  }
}

async function upgrade(filePaths) {
  const client = new pg.Client();
  await client.connect();
  try {
    await client.query("begin;");
    await client.query("drop schema if exists sqlfe cascade; create schema sqlfe; grant usage on schema sqlfe to sqlfe; set search_path to sqlfe, public;")
    for (const filePath of filePaths) {
      console.log({ filePath });
      await client.query((await readFile(filePath)).toString());
    }
    await client.query("commit;");
    console.log("commited");
  } catch (err) {
    await client.query("rollback;");
    throw err;
  } finally {
    await client.end();
  }
}

main(process.argv.slice(2))
  .then(() => console.log("done"))
  .catch(console.error);
