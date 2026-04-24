const Redis = require("ioredis");

const redis = new Redis({
  host: "127.0.0.1",
  port: 6379,

  // melhora estabilidade
  maxRetriesPerRequest: 3,
  enableReadyCheck: true,
});

redis.on("connect", () => {
  console.log("✅ Redis conectado");
});

redis.on("error", (err) => {
  console.error("❌ Redis erro:", err);
});

module.exports = redis;