#!/usr/bin/env node
/** REST API smoke test for DocSync. */
const base = process.env.BASE_URL || "http://localhost:3000";

async function req(path, options = {}) {
  const res = await fetch(`${base}${path}`, {
    headers: { "Content-Type": "application/json", ...options.headers },
    ...options,
  });
  const body = res.status === 204 ? null : await res.json().catch(() => null);
  return { res, body };
}

function assert(cond, msg) {
  if (!cond) throw new Error(msg);
}

async function main() {
  const staticPaths = ["/", "/css/styles.css", "/js/app.js"];
  for (const p of staticPaths) {
    const r = await fetch(`${base}${p}`);
    assert(r.ok, `static ${p} -> ${r.status}`);
  }
  console.log("Static assets: OK");

  const { res: h, body: health } = await req("/health");
  assert(h.ok && health.status === "healthy", "health failed");
  console.log("GET /health: OK");

  const { res: c, body: created } = await req("/api/documents", {
    method: "POST",
    body: JSON.stringify({ title: "API Smoke Test" }),
  });
  assert(c.status === 201 && created.id, "create failed");
  console.log("POST /api/documents: OK", created.id);

  const { res: g, body: got } = await req(`/api/documents/${created.id}`);
  assert(g.ok && got.title === "API Smoke Test", "get failed");
  console.log("GET /api/documents/:id: OK");

  const { res: u, body: updated } = await req(`/api/documents/${created.id}`, {
    method: "PUT",
    body: JSON.stringify({ content: "line one", version: 1 }),
  });
  assert(u.ok && updated.version === 2, "put failed");
  console.log("PUT /api/documents/:id: OK v2");

  const { res: bad } = await req(`/api/documents/${created.id}`, {
    method: "PUT",
    body: JSON.stringify({ content: "stale", version: 1 }),
  });
  assert(bad.status === 409, `expected 409 conflict, got ${bad.status}`);
  console.log("Version conflict 409: OK");

  const { res: l, body: list } = await req("/api/documents");
  assert(l.ok && Array.isArray(list) && list.some((d) => d.id === created.id), "list failed");
  console.log("GET /api/documents: OK count", list.length);

  const { res: noTitle } = await req("/api/documents", {
    method: "POST",
    body: JSON.stringify({}),
  });
  assert(noTitle.status === 400, "expected 400 for missing title");
  console.log("POST validation 400: OK");

  const { res: del } = await req(`/api/documents/${created.id}`, { method: "DELETE" });
  assert(del.status === 204, `expected 204 delete, got ${del.status}`);
  console.log("DELETE /api/documents/:id: OK");

  const { res: missingAfterDelete } = await req(`/api/documents/${created.id}`);
  assert(missingAfterDelete.status === 404, "expected 404 after delete");
  console.log("GET deleted document 404: OK");

  console.log("\nAll API checks passed.");
}

main().catch((e) => {
  console.error("API test FAILED:", e.message);
  process.exit(1);
});
