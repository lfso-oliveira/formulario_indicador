#!/usr/bin/env node
/**
 * Garante que a tabela e políticas existem no Supabase/Postgres.
 * Não é possível criar tabelas a partir do browser (chave anon).
 *
 * Uso:
 *   export DATABASE_URL="postgresql://postgres.[ref]:[PASSWORD]@aws-0-eu-central-1.pooler.supabase.com:6543/postgres"
 *   npm run db:ensure
 *
 * A connection string está em: Supabase → Project Settings → Database → URI (modo session ou transaction).
 * Requer SSL; use o URI que já inclui ?sslmode=require se o dashboard oferecer.
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import pg from "pg";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const schemaPath = path.join(root, "schema.sql");

function loadEnvFile() {
  const envPath = path.join(root, ".env");
  if (!fs.existsSync(envPath)) return;
  const text = fs.readFileSync(envPath, "utf8");
  for (const line of text.split("\n")) {
    const t = line.trim();
    if (!t || t.startsWith("#")) continue;
    const eq = t.indexOf("=");
    if (eq === -1) continue;
    const key = t.slice(0, eq).trim();
    let val = t.slice(eq + 1).trim();
    if (
      (val.startsWith('"') && val.endsWith('"')) ||
      (val.startsWith("'") && val.endsWith("'"))
    ) {
      val = val.slice(1, -1);
    }
    if (process.env[key] === undefined) process.env[key] = val;
  }
}

loadEnvFile();

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl || !databaseUrl.startsWith("postgres")) {
  console.error(
    "Defina DATABASE_URL com a connection string PostgreSQL do Supabase (Settings → Database).\n" +
      "Exemplo: DATABASE_URL='postgresql://...' npm run db:ensure"
  );
  process.exit(1);
}

if (!fs.existsSync(schemaPath)) {
  console.error("Ficheiro em falta:", schemaPath);
  process.exit(1);
}

const sql = fs.readFileSync(schemaPath, "utf8");

const client = new pg.Client({
  connectionString: databaseUrl,
  ssl:
    databaseUrl.includes("sslmode=require") || databaseUrl.includes("supabase")
      ? { rejectUnauthorized: false }
      : undefined,
});

try {
  await client.connect();
  await client.query(sql);
  console.log("Schema aplicado: indicadores_envios e políticas estão definidos.");
} catch (err) {
  console.error(err.message || err);
  process.exit(1);
} finally {
  await client.end().catch(() => {});
}
