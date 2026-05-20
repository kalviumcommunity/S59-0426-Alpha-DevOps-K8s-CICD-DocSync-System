const { randomUUID } = require("crypto");

class DocumentStore {
  constructor() {
    this.documents = new Map();
  }

  create(title) {
    const id = randomUUID();
    const doc = {
      id,
      title,
      content: "",
      version: 1,
      lastModified: new Date().toISOString(),
      history: [],
    };
    this.documents.set(id, doc);
    return doc;
  }

  get(id) {
    return this.documents.get(id) || null;
  }

  update(id, content, expectedVersion) {
    const doc = this.documents.get(id);
    if (!doc) {
      throw new Error(`Document ${id} not found`);
    }

    if (doc.version !== expectedVersion) {
      throw new Error(
        `Version conflict: expected ${expectedVersion}, current is ${doc.version}. ` +
          `Fetch the latest version and retry.`
      );
    }

    doc.history.push({
      version: doc.version,
      content: doc.content,
      timestamp: doc.lastModified,
    });

    doc.content = content;
    doc.version += 1;
    doc.lastModified = new Date().toISOString();

    return doc;
  }

  delete(id) {
    return this.documents.delete(id);
  }

  list() {
    return Array.from(this.documents.values()).map(({ id, title, version, lastModified }) => ({
      id,
      title,
      version,
      lastModified,
    }));
  }

  getVersion(id, version) {
    const doc = this.documents.get(id);
    if (!doc) return null;

    if (version === doc.version) {
      return { version: doc.version, content: doc.content };
    }

    const historical = doc.history.find((h) => h.version === version);
    return historical || null;
  }
}

module.exports = { DocumentStore };
