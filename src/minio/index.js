const express = require("express");
const Minio = require("minio");
const { createClient } = require("redis");

const app = express();
const port = 3000;

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

// =============================
// 🔴 REDIS
// =============================
const redisClient = createClient({
  socket: {
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT
  }
});

redisClient.on("error", (err) => console.log("Redis Error:", err));

(async () => {
  await redisClient.connect();
})();

// =============================
// 🔧 MINIO
// =============================
const minioClient = new Minio.Client({
  endPoint: process.env.MINIO_ENDPOINT,
  port: parseInt(process.env.MINIO_PORT),
  useSSL: true,
  accessKey: process.env.MINIO_ACCESS_KEY,
  secretKey: process.env.MINIO_SECRET_KEY,
});

// =============================
// 🔧 UTILS
// =============================

function isValidBucket(name) {
  return /^[a-z0-9-]+$/.test(name);
}

function formatSize(bytes) {
  return (bytes / 1024 / 1024).toFixed(2) + " MB";
}

function isMusic(file) {
  return file.match(/\.(mp3|wav|ogg)$/i);
}

function buildKey(prefix, bucket, path = "") {
  return `${prefix}:${bucket}:${path || "root"}`;
}

// =============================
// 📊 1. INFO COMPLETA DO BUCKET
// =============================
app.get("/bucket/:bucket", async (req, res) => {
  const bucket = req.params.bucket;

  if (!isValidBucket(bucket)) {
    return res.status(400).json({ error: "Bucket inválido" });
  }

  const key = buildKey("bucket", bucket);

  const cached = await redisClient.get(key);
  if (cached) {
    return res.json({ ...JSON.parse(cached), cache: "redis" });
  }

  try {
    const exists = await minioClient.bucketExists(bucket);
    if (!exists) {
      return res.status(404).json({ error: "Bucket não existe" });
    }

    const stream = minioClient.listObjectsV2(bucket, "", true);

    let totalSize = 0;
    let totalFiles = 0;
    let totalMp3 = 0;

    const folders = {};
    const files = [];

    stream.on("data", (obj) => {
      totalFiles++;
      totalSize += obj.size;

      if (isMusic(obj.name)) totalMp3++;

      const ext = obj.name.split(".").pop();

      files.push({
        name: obj.name,
        size: obj.size,
        sizeFormatted: formatSize(obj.size),
        type: ext,
        lastModified: obj.lastModified,
      });

      const parts = obj.name.split("/");
      if (parts.length > 1) {
        const folder = parts[0];

        if (!folders[folder]) {
          folders[folder] = {
            totalFiles: 0,
            totalSize: 0,
          };
        }

        folders[folder].totalFiles++;
        folders[folder].totalSize += obj.size;
      }
    });

    stream.on("end", async () => {
      const response = {
        bucket,
        totalFiles,
        totalMp3,
        totalSize,
        totalSizeFormatted: formatSize(totalSize),
        folders,
        files,
      };

      await redisClient.setEx(key, 60, JSON.stringify(response));

      res.json({ ...response, cache: "miss" });
    });

    stream.on("error", (err) => {
      res.status(500).json({ error: err.message });
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// =============================
// 📁 2. LISTAR PASTAS
// =============================
app.get("/folders/:bucket", async (req, res) => {
  const bucket = req.params.bucket;

  if (!isValidBucket(bucket)) {
    return res.status(400).json({ error: "Bucket inválido" });
  }

  const key = buildKey("folders", bucket);

  const cached = await redisClient.get(key);
  if (cached) {
    return res.json({ ...JSON.parse(cached), cache: "redis" });
  }

  try {
    const exists = await minioClient.bucketExists(bucket);
    if (!exists) {
      return res.status(404).json({ error: "Bucket não existe" });
    }

    const stream = minioClient.listObjectsV2(bucket, "", true);

    let totalFiles = 0;
    let totalSize = 0;
    let totalMp3 = 0;

    const folders = {};

    stream.on("data", (obj) => {
      totalFiles++;
      totalSize += obj.size;

      if (isMusic(obj.name)) totalMp3++;

      if (!obj.name.includes("/")) return;

      const folder = obj.name.split("/")[0];

      if (!folders[folder]) {
        folders[folder] = {
          totalFiles: 0,
          totalMp3: 0,
          totalSize: 0
        };
      }

      folders[folder].totalFiles++;
      folders[folder].totalSize += obj.size;

      if (isMusic(obj.name)) {
        folders[folder].totalMp3++;
      }
    });

    stream.on("end", async () => {
      Object.keys(folders).forEach((folder) => {
        folders[folder].totalSizeFormatted =
          (folders[folder].totalSize / 1024 / 1024).toFixed(2) + " MB";
      });

      const response = {
        bucket,
        totalFiles,
        totalMp3,
        totalSize,
        totalSizeFormatted: formatSize(totalSize),
        totalFolders: Object.keys(folders).length,
        folders
      };

      await redisClient.setEx(key, 30, JSON.stringify(response));

      res.json({ ...response, cache: "miss" });
    });

    stream.on("error", (err) => {
      res.status(500).json({ error: err.message });
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// =============================
// 📁 3. INFO DE UMA PASTA
// =============================
app.get("/folder/:bucket/*", async (req, res) => {
  const bucket = req.params.bucket;

  if (!isValidBucket(bucket)) {
    return res.status(400).json({ error: "Bucket inválido" });
  }

  try {
    const path = decodeURIComponent(req.params[0] || "");
    const key = buildKey("folder", bucket, path);

    const cached = await redisClient.get(key);
    if (cached) {
      return res.json({ ...JSON.parse(cached), cache: "redis" });
    }

    const prefix = path ? `${path}/` : "";
    const stream = minioClient.listObjectsV2(bucket, prefix, true);

    let totalSize = 0;
    let totalFiles = 0;
    let totalMp3 = 0;

    const musics = [];

    stream.on("data", (obj) => {
      totalFiles++;
      totalSize += obj.size;

      if (isMusic(obj.name)) {
        totalMp3++;

        musics.push({
          name: obj.name.split("/").pop(),
          path: obj.name,
          size: obj.size,
          sizeFormatted: formatSize(obj.size),
          lastModified: obj.lastModified,
        });
      }
    });

    stream.on("end", async () => {
      const response = {
        bucket,
        path,
        totalFiles,
        totalMp3,
        totalSize,
        totalSizeFormatted: formatSize(totalSize),
        musics
      };

      await redisClient.setEx(key, 30, JSON.stringify(response));

      res.json({ ...response, cache: "miss" });
    });

    stream.on("error", (err) => {
      res.status(500).json({ error: err.message });
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// =============================
// 🎵 4. LISTAR MÚSICAS
// =============================
app.get("/musics/:bucket/:folder", async (req, res) => {
  const { bucket, folder } = req.params;

  if (!isValidBucket(bucket)) {
    return res.status(400).json({ error: "Bucket inválido" });
  }

  const key = buildKey("musics", bucket, folder);

  const cached = await redisClient.get(key);
  if (cached) {
    return res.json({ data: JSON.parse(cached), cache: "redis" });
  }

  try {
    const prefix = `${folder}/`;
    const stream = minioClient.listObjectsV2(bucket, prefix, true);

    const musics = [];

    stream.on("data", (obj) => {
      if (!isMusic(obj.name)) return;

      musics.push({
        name: obj.name.split("/").pop(),
        path: obj.name,
        size: obj.size,
        sizeFormatted: formatSize(obj.size),
        lastModified: obj.lastModified,
      });
    });

    stream.on("end", async () => {
      await redisClient.setEx(key, 20, JSON.stringify(musics));
      res.json({ data: musics, cache: "miss" });
    });

    stream.on("error", (err) => {
      res.status(500).json({ error: err.message });
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// =============================
// ▶️ 5. PLAY
// =============================
app.get("/play/:bucket/*", async (req, res) => {
  const bucket = req.params.bucket;

  if (!isValidBucket(bucket)) {
    return res.status(400).json({ error: "Bucket inválido" });
  }

  try {
    const objectName = decodeURIComponent(req.params[0]);

    const url = await minioClient.presignedGetObject(
      bucket,
      objectName,
      60 * 60
    );

    res.json({
      file: objectName,
      url,
      expiresIn: "1h"
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// =============================
// 🧹 LIMPAR CACHE
// =============================
app.get("/cache/clear/:bucket", async (req, res) => {
  const bucket = req.params.bucket;

  const keys = await redisClient.keys(`*:${bucket}:*`);

  if (keys.length) {
    await redisClient.del(keys);
  }

  res.json({ message: "Cache limpo", total: keys.length });
});


// =============================
// 🔍 HEALTH CHECK
// =============================
app.get("/", (req, res) => {
  res.send("API MinIO + Redis OK 🚀");
});


app.listen(port, () => {
  console.log(`Servidor rodando em http://localhost:${port}`);
});