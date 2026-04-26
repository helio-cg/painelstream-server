const Fastify = require("fastify");
const path = require("path");

const { listFiles } = require("./fs");
const { decodePath } = require("./utils");
const { processMP3List } = require("./mp3");

const app = Fastify({ logger: true });

// ===== CONFIG =====
function getBaseDir(username) {
  return `/home/${username}/midia`;
}

// ===== VALIDAR USER =====
function isValidUsername(username) {
  return /^[a-zA-Z0-9_-]+$/.test(username);
}

// ===== SEGURANÇA PATH =====
function safePath(base, target) {
  const resolved = path.resolve(base, target || "");

  if (!resolved.startsWith(base)) {
    throw new Error("acesso inválido");
  }

  return resolved;
}

// ===== RATE LIMIT =====
app.register(require("@fastify/rate-limit"), {
  max: 100,
  timeWindow: "1 minute",
});

// ===== ROOT =====
app.get("/", async () => {
  return {
    status: "ok",
    servico: "filesystem-proxy",
    publico: true,
    timestamp: new Date(),
  };
});

// ===== LISTA RAIZ =====
app.get("/usuario/:username", async (req, reply) => {
  const { username } = req.params;

  if (!isValidUsername(username)) {
    return reply.code(400).send({ erro: "usuário inválido" });
  }

  const base = getBaseDir(username);

  try {
    const files = await listFiles(base);

    return {
      path: base,
      conteudo: files,
    };
  } catch (e) {
    req.log.error(e);
    return reply.code(500).send({ erro: "erro ao acessar diretório" });
  }
});

// ===== LISTA PASTA =====
app.get("/usuario/:username/pasta/:b64", async (req, reply) => {
  const { username, b64 } = req.params;

  if (!isValidUsername(username)) {
    return reply.code(400).send({ erro: "usuário inválido" });
  }

  try {
    const decoded = decodePath(b64);
    const base = getBaseDir(username);
    const safe = safePath(base, decoded);

    const files = await listFiles(safe);
    const result = await processMP3List(files, safe);

    return {
      path: safe,
      conteudo: result,
    };
  } catch (e) {
    req.log.error(e);
    return reply.code(403).send({ erro: e.message });
  }
});

// ===== START =====
app.listen({ port: 3000, host: "0.0.0.0" })
  .then(() => console.log("🚀 API rodando em http://localhost:3000"))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });