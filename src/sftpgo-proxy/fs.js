const fs = require("fs/promises");
const path = require("path");

async function listFiles(baseDir) {
  const entries = await fs.readdir(baseDir, { withFileTypes: true });

  return entries.map((entry) => ({
    nome: entry.name,
    tipo: entry.isDirectory() ? "pasta" : "arquivo",
  }));
}

module.exports = { listFiles };