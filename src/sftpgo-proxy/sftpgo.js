const axios = require("axios");
const redis = require("./redis");

const BASE = "http://localhost:8080/api/v2";

async function login(username, password) {
  const res = await axios.post(`${BASE}/token`, {
    username,
    password,
  });

  const token = res.data.access_token;
  await redis.setex(`token:${username}`, 600, token);

  return token;
}

async function getToken(username) {
  const token = await redis.get(`token:${username}`);
  if (!token) throw new Error("Token expirado");
  return token;
}

async function listFiles(username, path) {
  const token = await getToken(username);

  const key = `list:${username}:${path}`;
  const cached = await redis.get(key);
  if (cached) return JSON.parse(cached);

  const res = await axios.get(`${BASE}/user/files`, {
    headers: { Authorization: `Bearer ${token}` },
    params: { path },
  });

  await redis.setex(key, 60, JSON.stringify(res.data));
  return res.data;
}

module.exports = { login, listFiles };