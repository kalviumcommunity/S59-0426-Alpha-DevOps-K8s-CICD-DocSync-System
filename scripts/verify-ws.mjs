#!/usr/bin/env node
/** One-off WebSocket smoke test for DocSync. */
import WebSocket from "ws";

const base = process.env.BASE_URL || "http://localhost:3000";
const wsUrl = base.replace(/^http/, "ws") + "/ws";

async function main() {
  const create = await fetch(`${base}/api/documents`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title: "WS Smoke Test" }),
  });
  if (!create.ok) throw new Error(`create failed ${create.status}`);
  const doc = await create.json();

  const updated = await new Promise((resolve, reject) => {
    const ws = new WebSocket(wsUrl);
    const timeout = setTimeout(() => {
      ws.close();
      reject(new Error("timeout waiting for broadcast"));
    }, 5000);

    ws.on("open", () => {
      ws.send(JSON.stringify({ type: "subscribe", documentId: doc.id }));
    });

    ws.on("message", (raw) => {
      const msg = JSON.parse(raw.toString());
      if (msg.type === "update" && msg.document?.id === doc.id) {
        clearTimeout(timeout);
        ws.close();
        resolve(msg.document);
      }
    });

    ws.on("error", reject);

    setTimeout(async () => {
      await fetch(`${base}/api/documents/${doc.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ content: "ws-broadcast-ok", version: doc.version }),
      });
    }, 200);
  });

  if (updated.content !== "ws-broadcast-ok") {
    throw new Error(`unexpected content: ${updated.content}`);
  }
  console.log("WebSocket broadcast OK", { id: doc.id, version: updated.version });

  const deleteDoc = await fetch(`${base}/api/documents`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title: "WS Delete Smoke Test" }),
  });
  if (!deleteDoc.ok) throw new Error(`delete test create failed ${deleteDoc.status}`);
  const deletable = await deleteDoc.json();

  const deleted = await new Promise((resolve, reject) => {
    const ws = new WebSocket(wsUrl);
    const timeout = setTimeout(() => {
      ws.close();
      reject(new Error("timeout waiting for delete broadcast"));
    }, 5000);

    ws.on("open", () => {
      ws.send(JSON.stringify({ type: "subscribe", documentId: deletable.id }));
    });

    ws.on("message", (raw) => {
      const msg = JSON.parse(raw.toString());
      if (msg.type === "deleted" && msg.documentId === deletable.id) {
        clearTimeout(timeout);
        ws.close();
        resolve(msg);
      }
    });

    ws.on("error", reject);

    setTimeout(async () => {
      await fetch(`${base}/api/documents/${deletable.id}`, { method: "DELETE" });
    }, 200);
  });

  console.log("WebSocket delete broadcast OK", { id: deleted.documentId });
}

main().catch((err) => {
  console.error("WebSocket test FAILED:", err.message);
  process.exit(1);
});
