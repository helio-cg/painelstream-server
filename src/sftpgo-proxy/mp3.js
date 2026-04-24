const mm = require("music-metadata");
const fs = require("fs");
const redis = require("./redis");

async function getMP3Info(filePath) {
  const key = `mp3:${filePath}`;

  const cached = await redis.get(key);
  if (cached) return JSON.parse(cached);

  try {
    const stream = fs.createReadStream(filePath);
    const metadata = await mm.parseStream(stream);

    const info = {
      titulo: metadata.common.title,
      artista: metadata.common.artist,
      album: metadata.common.album,
      duracao: Math.floor(metadata.format.duration),
      bitrate: metadata.format.bitrate,
    };

    await redis.setex(key, 300, JSON.stringify(info));
    return info;
  } catch {
    return { erro: "falha ao ler mp3" };
  }
}

// ⚡ paralelizar vários mp3
async function processMP3List(files, basePath) {
  const tasks = files.map(async (f) => {
    if (!f.is_dir && f.name.toLowerCase().endsWith(".mp3")) {
      const full = `${basePath}/${f.name}`;
      f.mp3 = await getMP3Info(full);
    }
    return f;
  });

  return Promise.all(tasks);
}

module.exports = { processMP3List };