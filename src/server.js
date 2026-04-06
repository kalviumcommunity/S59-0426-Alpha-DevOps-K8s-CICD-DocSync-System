const express = require("express");
const http = require("http");
const { WebSocketServer } = require("ws");
const { DocumentStore } = require("./document");

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: "/ws" });

const store = new DocumentStore();

app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ status: "healthy", uptime: process.uptime() });
});

app.get("/api/documents", (_req, res) => {
  res.json(store.list());
});

app.post("/api/documents", (req, res) => {
  const { title } = req.body;
  if (!title) {
    return res.status(400).json({ error: "Title is required" });
  }
  const doc = store.create(title);
  res.status(201).json(doc);
});

app.get("/api/documents/:id", (req, res) => {
  const doc = store.get(req.params.id);
  if (!doc) {
    return res.status(404).json({ error: "Document not found" });
  }
  res.json(doc);
});

app.put("/api/documents/:id", (req, res) => {
  const { content, version } = req.body;
  try {
    const doc = store.update(req.params.id, content, version);
    broadcast(req.params.id, doc);
    res.json(doc);
  } catch (err) {
    const status = err.message.includes("conflict") ? 409 : 404;
    res.status(status).json({ error: err.message });
  }
});

const clients = new Map();

wss.on("connection", (ws) => {
  ws.on("message", (raw) => {
    try {
      const msg = JSON.parse(raw);
      if (msg.type === "subscribe" && msg.documentId) {
        if (!clients.has(msg.documentId)) {
          clients.set(msg.documentId, new Set());
        }
        clients.get(msg.documentId).add(ws);
        ws.documentId = msg.documentId;
      }
    } catch {
      /* ignore malformed messages */
    }
  });

  ws.on("close", () => {
    if (ws.documentId && clients.has(ws.documentId)) {
      clients.get(ws.documentId).delete(ws);
    }
  });
});

function broadcast(documentId, doc) {
  const subscribers = clients.get(documentId);
  if (!subscribers) return;

  const payload = JSON.stringify({ type: "update", document: doc });
  for (const client of subscribers) {
    if (client.readyState === client.OPEN) {
      client.send(payload);
    }
  }
}

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`DocSync server running on port ${PORT}`);
});

module.exports = { app, server };
