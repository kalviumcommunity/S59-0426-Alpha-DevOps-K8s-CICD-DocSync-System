const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const { DocumentStore } = require("../src/document");

describe("DocumentStore", () => {
  it("should create a document with a unique id", () => {
    const store = new DocumentStore();
    const doc = store.create("Test Doc");

    assert.ok(doc.id);
    assert.equal(doc.title, "Test Doc");
    assert.equal(doc.content, "");
    assert.equal(doc.version, 1);
  });

  it("should retrieve a document by id", () => {
    const store = new DocumentStore();
    const created = store.create("My Doc");
    const fetched = store.get(created.id);

    assert.deepEqual(fetched, created);
  });

  it("should return null for non-existent documents", () => {
    const store = new DocumentStore();
    assert.equal(store.get("non-existent-id"), null);
  });

  it("should update a document with correct version", () => {
    const store = new DocumentStore();
    const doc = store.create("Editable Doc");

    const updated = store.update(doc.id, "Hello, World!", 1);

    assert.equal(updated.content, "Hello, World!");
    assert.equal(updated.version, 2);
  });

  it("should reject updates with wrong version (conflict detection)", () => {
    const store = new DocumentStore();
    const doc = store.create("Conflict Doc");

    store.update(doc.id, "Edit 1", 1);

    assert.throws(
      () => store.update(doc.id, "Edit 2", 1),
      /Version conflict/
    );
  });

  it("should preserve edit history", () => {
    const store = new DocumentStore();
    const doc = store.create("History Doc");

    store.update(doc.id, "Version 2 content", 1);
    store.update(doc.id, "Version 3 content", 2);

    const current = store.get(doc.id);
    assert.equal(current.version, 3);
    assert.equal(current.history.length, 2);
    assert.equal(current.history[0].content, "");
    assert.equal(current.history[1].content, "Version 2 content");
  });

  it("should list all documents", () => {
    const store = new DocumentStore();
    store.create("Doc A");
    store.create("Doc B");

    const list = store.list();
    assert.equal(list.length, 2);
    assert.ok(list.every((d) => d.id && d.title));
  });

  it("should delete a document", () => {
    const store = new DocumentStore();
    const doc = store.create("Delete Me");

    assert.equal(store.delete(doc.id), true);
    assert.equal(store.get(doc.id), null);
    assert.equal(store.list().length, 0);
  });

  it("should return false when deleting a missing document", () => {
    const store = new DocumentStore();

    assert.equal(store.delete("missing-id"), false);
  });

  it("should retrieve a specific historical version", () => {
    const store = new DocumentStore();
    const doc = store.create("Versioned Doc");
    store.update(doc.id, "v2", 1);
    store.update(doc.id, "v3", 2);

    const v1 = store.getVersion(doc.id, 1);
    assert.equal(v1.content, "");

    const v2 = store.getVersion(doc.id, 2);
    assert.equal(v2.content, "v2");

    const v3 = store.getVersion(doc.id, 3);
    assert.equal(v3.content, "v3");
  });
});
