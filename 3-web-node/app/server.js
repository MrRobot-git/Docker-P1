const express = require("express");
const mysql = require("mysql2/promise");

const app = express();
const PORT = process.env.PORT || 3000;

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 5,
});

const escapeHtml = (v) =>
  String(v).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

app.get("/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.send("ok");
  } catch (err) {
    res.status(503).send("db error");
  }
});

app.get("/", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT id, nombre, categoria, precio, stock FROM productos ORDER BY id");
    const filas = rows
      .map(
        (r) => `<tr><td>${r.id}</td><td>${escapeHtml(r.nombre)}</td><td>${escapeHtml(r.categoria)}</td>` +
               `<td class="num">${Number(r.precio).toFixed(2)} €</td><td class="num">${r.stock}</td></tr>`
      )
      .join("\n");
    res.send(`<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Productos</title>
  <style>
    body { font-family: system-ui, sans-serif; margin: 2rem auto; max-width: 800px; padding: 0 1rem; color: #222; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ccc; padding: .5rem .75rem; text-align: left; }
    th { background: #1f4e79; color: #fff; }
    tr:nth-child(even) { background: #f4f7fa; }
    .num { text-align: right; }
  </style>
</head>
<body>
  <h1>Productos (MySQL → Node.js → Nginx)</h1>
  <table>
    <thead><tr><th>ID</th><th>Nombre</th><th>Categoría</th><th>Precio</th><th>Stock</th></tr></thead>
    <tbody>
${filas}
    </tbody>
  </table>
  <p>${rows.length} registros leídos de la base de datos.</p>
</body>
</html>`);
  } catch (err) {
    console.error(err);
    res.status(500).send("Error consultando la base de datos");
  }
});

app.listen(PORT, () => console.log(`Server is running on port ${PORT}`));
