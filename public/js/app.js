/* eslint-env browser */

(function () {
  const $ = (sel) => document.querySelector(sel);

  const els = {
    apiStatus: $("#api-status"),
    wsStatus: $("#ws-status"),
    docList: $("#doc-list"),
    listEmpty: $("#list-empty"),
    createForm: $("#create-form"),
    newTitle: $("#new-title"),
    editorEmpty: $("#editor-empty"),
    editorActive: $("#editor-active"),
    docTitle: $("#doc-title"),
    docMeta: $("#doc-meta"),
    docContent: $("#doc-content"),
    saveBtn: $("#save-btn"),
    reloadBtn: $("#reload-btn"),
    deleteBtn: $("#delete-btn"),
    saveStatus: $("#save-status"),
  };

  let activeDoc = null;
  let ws = null;

  const wsUrl = `${location.protocol === "https:" ? "wss" : "ws"}://${location.host}/ws`;

  async function api(path, options = {}) {
    const res = await fetch(path, {
      headers: { "Content-Type": "application/json", ...options.headers },
      ...options,
    });
    const body = res.status === 204 ? null : await res.json().catch(() => null);
    if (!res.ok) {
      const msg = body?.error || res.statusText || "Request failed";
      throw new Error(msg);
    }
    return body;
  }

  function setBadge(el, text, kind) {
    el.textContent = text;
    el.className = `badge badge-${kind}`;
  }

  async function checkHealth() {
    try {
      const data = await api("/health");
      setBadge(els.apiStatus, `API · ${data.status}`, "ok");
    } catch {
      setBadge(els.apiStatus, "API unreachable", "warn");
    }
  }

  function connectWs(documentId) {
    if (ws) {
      ws.close();
      ws = null;
    }
    setBadge(els.wsStatus, "Connecting…", "muted");

    ws = new WebSocket(wsUrl);

    ws.onopen = () => {
      setBadge(els.wsStatus, "Live", "ok");
      ws.send(JSON.stringify({ type: "subscribe", documentId }));
    };

    ws.onclose = () => {
      setBadge(els.wsStatus, "Offline", "muted");
    };

    ws.onerror = () => {
      setBadge(els.wsStatus, "Error", "warn");
    };

    ws.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data);
        if (msg.type === "update" && msg.document && activeDoc?.id === msg.document.id) {
          applyDocument(msg.document);
        } else if (msg.type === "deleted" && msg.documentId === activeDoc?.id) {
          clearEditor("This document was deleted in another tab.");
          loadList().catch(() => setBadge(els.apiStatus, "API error", "warn"));
        }
      } catch {
        /* ignore */
      }
    };
  }

  function formatTime(iso) {
    try {
      return new Date(iso).toLocaleString();
    } catch {
      return iso;
    }
  }

  function applyDocument(doc) {
    activeDoc = {
      id: doc.id,
      title: doc.title,
      content: doc.content,
      version: doc.version,
      lastModified: doc.lastModified,
    };
    els.docTitle.textContent = doc.title;
    els.docMeta.textContent = `v${doc.version} · ${formatTime(doc.lastModified)}`;
    els.docContent.value = doc.content ?? "";
    showEditor(true);
    highlightActive(doc.id);
  }

  function showEditor(show) {
    els.editorEmpty.classList.toggle("hidden", show);
    els.editorActive.classList.toggle("hidden", !show);
  }

  function clearEditor(message = "Select a document or create a new one.") {
    activeDoc = null;
    if (ws) {
      ws.close();
      ws = null;
    }
    els.docTitle.textContent = "";
    els.docMeta.textContent = "";
    els.docContent.value = "";
    els.editorEmpty.querySelector("p").textContent = message;
    setSaveStatus("");
    showEditor(false);
    highlightActive(null);
  }

  function highlightActive(id) {
    els.docList.querySelectorAll("button[data-id]").forEach((btn) => {
      btn.classList.toggle("active", btn.dataset.id === id);
    });
  }

  async function loadList() {
    const docs = await api("/api/documents");
    els.docList.innerHTML = "";
    els.listEmpty.classList.toggle("hidden", docs.length > 0);

    for (const doc of docs) {
      const li = document.createElement("li");
      const btn = document.createElement("button");
      btn.type = "button";
      btn.dataset.id = doc.id;
      btn.innerHTML = `${escapeHtml(doc.title)}<span class="doc-item-meta">v${doc.version}</span>`;
      btn.addEventListener("click", () => openDocument(doc.id));
      li.appendChild(btn);
      els.docList.appendChild(li);
    }
  }

  function escapeHtml(str) {
    const d = document.createElement("div");
    d.textContent = str;
    return d.innerHTML;
  }

  async function openDocument(id) {
    setSaveStatus("");
    const doc = await api(`/api/documents/${id}`);
    applyDocument(doc);
    connectWs(id);
  }

  async function saveDocument() {
    if (!activeDoc) return;
    setSaveStatus("Saving…", "");
    els.saveBtn.disabled = true;
    try {
      const doc = await api(`/api/documents/${activeDoc.id}`, {
        method: "PUT",
        body: JSON.stringify({
          content: els.docContent.value,
          version: activeDoc.version,
        }),
      });
      applyDocument(doc);
      setSaveStatus("Saved", "ok");
      await loadList();
    } catch (err) {
      setSaveStatus(err.message, "err");
    } finally {
      els.saveBtn.disabled = false;
    }
  }

  async function deleteDocument() {
    if (!activeDoc) return;

    const { id, title } = activeDoc;
    if (!window.confirm(`Delete "${title}"? This cannot be undone.`)) {
      return;
    }

    setSaveStatus("Deleting…", "");
    els.deleteBtn.disabled = true;
    try {
      await api(`/api/documents/${id}`, { method: "DELETE" });
      await loadList();
      clearEditor("Document deleted. Select another document or create a new one.");
    } catch (err) {
      setSaveStatus(err.message, "err");
    } finally {
      els.deleteBtn.disabled = false;
    }
  }

  function setSaveStatus(text, kind) {
    els.saveStatus.textContent = text;
    els.saveStatus.className = "save-status" + (kind ? ` ${kind}` : "");
  }

  els.createForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const title = els.newTitle.value.trim();
    if (!title) return;
    try {
      const doc = await api("/api/documents", {
        method: "POST",
        body: JSON.stringify({ title }),
      });
      els.newTitle.value = "";
      await loadList();
      await openDocument(doc.id);
    } catch (err) {
      alert(err.message);
    }
  });

  els.saveBtn.addEventListener("click", saveDocument);
  els.deleteBtn.addEventListener("click", deleteDocument);
  els.reloadBtn.addEventListener("click", () => {
    if (activeDoc) openDocument(activeDoc.id);
  });

  document.addEventListener("keydown", (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key === "s") {
      e.preventDefault();
      saveDocument();
    }
  });

  checkHealth();
  loadList().catch(() => setBadge(els.apiStatus, "API error", "warn"));
})();
