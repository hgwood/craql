import pg from "pg";
import postgresMigrations from "postgres-migrations";

async function migrate() {
  const client = new pg.Client();
  await client.connect();
  try {
    await postgresMigrations.migrate({ client }, "migrations");
  } finally {
    await client.end();
  }
}

migrate()
  .then(() => console.log("done"))
  .catch(console.error);
