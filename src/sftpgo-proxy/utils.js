const path = require("path");

function decodePath(b64) {
  return Buffer.from(b64, "base64").toString("utf-8");
}

// 🔒 garante que o path pertence ao usuário
function safePath(username, inputPath) {
  const base = `/home/${username}/midia`;

  const resolved = path.resolve(inputPath);

  if (!resolved.startsWith(base)) {
    throw new Error("Acesso negado: path inválido");
  }

  return resolved;
}

module.exports = { decodePath, safePath };