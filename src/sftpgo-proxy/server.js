const Fastify = require("fastify");
const { login, listFiles } = require("./sftpgo");
const { decodePath, safePath } = require("./utils");
const { processMP3List } = require("./mp3");

const app = Fastify();

// login
app.post("/login", async (req, reply) => {
  const { username, password } = req.body;

  try {
    const token = await login(username, password);
    return { ok: true, token };
  } catch {
    reply.code(401).send({ erro: "login inválido" });
  }
});

// raiz
app.get("/usuario/:username", async (req) => {
  const { username } = req.params;

  const base = `/home/${username}/midia`;

  const files = await listFiles(username, base);

  return {
    path: base,
    conteudo: files,
  };
});

// pasta segura
app.get("/usuario/:username/pasta/:b64", async (req, reply) => {
  const { username, b64 } = req.params;

  try {
    const decoded = decodePath(b64);
    const safe = safePath(username, decoded);

    const files = await listFiles(username, safe);

    const result = await processMP3List(files, safe);

    return {
      path: safe,
      conteudo: result,
    };
  } catch (e) {
    reply.code(403).send({ erro: e.message });
  }
});

app.listen({ port: 3000, host: "127.0.0.1" });