const express = require("express");
const Minio = require("minio");

const app = express();
const port = 3000;

const minioClient = new Minio.Client({
  endPoint: process.env.MINIO_ENDPOINT,
  port: parseInt(process.env.MINIO_PORT),
  useSSL: false,
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

// =============================
// 📊 1. INFO COMPLETA DO BUCKET
// =============================
app.get("/bucket/:bucket", async (req, res) => {
  const bucket = req.params.bucket;

  if (!isValidBucket(bucket)) {
    return res.status(400).json({ error: "Bucket inválido" });
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

    stream.on("end", () => {
      res.json({
        bucket,
        totalFiles,
        totalMp3,
        totalSize,
        totalSizeFormatted: formatSize(totalSize),
        folders,
        files,
      });
    });

    stream.on("error", (err) => {
      res.status(500).json({ error: err.message });
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// =============================
// 📁 2. LISTAR PASTAS (RAIZ)
// =============================
app.get("/folders/:bucket", async (req, res) => {
  const bucket = req.params.bucket;

  if (!/^[a-z0-9-]+$/.test(bucket)) {
    return res.status(400).json({ error: "Bucket inválido" });
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

      if (obj.name.match(/\.(mp3|wav|ogg)$/i)) {
        totalMp3++;
      }

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

      if (obj.name.match(/\.(mp3|wav|ogg)$/i)) {
        folders[folder].totalMp3++;
      }
    });

    stream.on("end", () => {

      // formatar tamanhos
      Object.keys(folders).forEach((folder) => {
        folders[folder].totalSizeFormatted =
          (folders[folder].totalSize / 1024 / 1024).toFixed(2) + " MB";
      });

      res.json({
        bucket,
        totalFiles,
        totalMp3,
        totalSize,
        totalSizeFormatted: (totalSize / 1024 / 1024).toFixed(2) + " MB",
        totalFolders: Object.keys(folders).length,
        folders
      });
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

    stream.on("end", () => {
      res.json({
        bucket,
        path,
        totalFiles,
        totalMp3,
        totalSize,
        totalSizeFormatted: formatSize(totalSize),
        musics
      });
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

    stream.on("end", () => {
      res.json(musics);
    });

    stream.on("error", (err) => {
      res.status(500).json({ error: err.message });
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// =============================
// ▶️ 5. PLAY (URL TEMPORÁRIA)
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
// 🔍 HEALTH CHECK
// =============================
app.get("/", (req, res) => {
  res.send("API MinIO OK 🚀");
});


app.listen(port, () => {
  console.log(`Servidor rodando em http://localhost:${port}`);
});