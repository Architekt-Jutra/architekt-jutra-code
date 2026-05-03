// static-nodes.cypher — Operational Topology Graph seed for cascading-shared-dependency.
// Time-relative values use a fixed anchor: INCIDENT_NOW = 2026-04-17T14:00:00Z.
// Other timestamps are expressed relative to this anchor in comments; stored as ISO-8601 strings.
// All statements idempotent via MERGE.

// ===== Services =====
MERGE (s:Service {name: "host-app"})
  SET s.tier = "core", s.runtime = "jvm", s.release_channel = "stable", s.lifecycle = "production";

MERGE (s:Service {name: "ai-description"})
  SET s.tier = "extension", s.runtime = "jvm", s.release_channel = "stable", s.lifecycle = "production";

MERGE (s:Service {name: "warehouse"})
  SET s.tier = "extension", s.runtime = "node", s.release_channel = "stable", s.lifecycle = "production";

MERGE (s:Service {name: "box-size"})
  SET s.tier = "extension", s.runtime = "node", s.release_channel = "stable", s.lifecycle = "production";

// ===== Datastores =====
MERGE (d:Datastore {name: "postgresql-primary"})
  SET d.kind = "relational", d.capacity_tier = "shared";
MERGE (d:Datastore {name: "redis-cache"})
  SET d.kind = "keyvalue", d.capacity_tier = "dedicated";
MERGE (d:Datastore {name: "minio-assets"})
  SET d.kind = "object", d.capacity_tier = "shared";

// ===== Endpoints (child of host-app) =====
MERGE (e:Endpoint {path: "/api/products/{id}", method: "GET", version: "v1"});
MERGE (e:Endpoint {path: "/api/plugins/{id}/objects", method: "POST", version: "v1"});
MERGE (e:Endpoint {path: "/api/categories", method: "GET", version: "v1"});

// ===== Dependencies =====
MERGE (d:Dependency {name: "litellm-proxy"})
  SET d.vendor = "internal", d.kind = "proxy";
MERGE (d:Dependency {name: "langfuse-tracing"})
  SET d.vendor = "internal", d.kind = "saas";
MERGE (d:Dependency {name: "presidio-pii"})
  SET d.vendor = "external", d.kind = "saas";

// ===== Feature Gates =====
MERGE (g:FeatureGate {name: "warehouse-full-inventory-sync"})
  SET g.state = "on", g.description = "enable hourly full inventory sync via product API";
MERGE (g:FeatureGate {name: "ai-description-lazy-cache"})
  SET g.state = "on", g.description = "use lazy loader for description cache";
MERGE (g:FeatureGate {name: "box-size-beta-ui"})
  SET g.state = "rollout", g.description = "new BoxSize UI for beta tenants";

// ===== Teams =====
MERGE (t:Team {name: "platform-core"}) SET t.kind = "platform";
MERGE (t:Team {name: "ai-team"}) SET t.kind = "product";
MERGE (t:Team {name: "warehouse-product"}) SET t.kind = "product";

// ===== Persons =====
MERGE (p:Person {handle: "a.nowak@example.com"}) SET p.email = "a.nowak@example.com";
MERGE (p:Person {handle: "p.warehouse@example.com"}) SET p.email = "p.warehouse@example.com";
MERGE (p:Person {handle: "m.ai@example.com"}) SET p.email = "m.ai@example.com";

// ===== Revisions =====
// rev-001: gate toggle, 4h ago (2026-04-17T10:00:00Z) — KEY (triggers the incident)
MERGE (r:Revision {id: "rev-001"})
  SET r.target_kind = "gate",
      r.target = "warehouse-full-inventory-sync",
      r.kind = "toggle",
      r.at = "2026-04-17T10:00:00Z",
      r.summary = "enable full inventory sync";

// rev-002: ai-description deploy, 18h ago — LEAD 1
MERGE (r:Revision {id: "rev-002"})
  SET r.target_kind = "service",
      r.target = "ai-description",
      r.kind = "deploy",
      r.at = "2026-04-16T20:00:00Z",
      r.summary = "v2.1 to v2.2 cache refactor";

// rev-003: litellm-proxy config, 5 days ago — background
MERGE (r:Revision {id: "rev-003"})
  SET r.target_kind = "dependency",
      r.target = "litellm-proxy",
      r.kind = "config",
      r.at = "2026-04-12T14:00:00Z",
      r.summary = "add claude-haiku route";

// rev-004: host-app deploy, 3 days ago — background
MERGE (r:Revision {id: "rev-004"})
  SET r.target_kind = "service",
      r.target = "host-app",
      r.kind = "deploy",
      r.at = "2026-04-14T14:00:00Z",
      r.summary = "v4.0.5 framework upgrade";

// rev-005: warehouse deploy, 7 days ago — background
MERGE (r:Revision {id: "rev-005"})
  SET r.target_kind = "service",
      r.target = "warehouse",
      r.kind = "deploy",
      r.at = "2026-04-10T14:00:00Z",
      r.summary = "v1.4 to v1.5 ui polish";

// ========== EDGES ==========

// --- owned_by ---
MATCH (s:Service {name: "host-app"}), (t:Team {name: "platform-core"}) MERGE (s)-[:owned_by]->(t);
MATCH (s:Service {name: "ai-description"}), (t:Team {name: "ai-team"}) MERGE (s)-[:owned_by]->(t);
MATCH (s:Service {name: "warehouse"}), (t:Team {name: "warehouse-product"}) MERGE (s)-[:owned_by]->(t);
MATCH (s:Service {name: "box-size"}), (t:Team {name: "warehouse-product"}) MERGE (s)-[:owned_by]->(t);

MATCH (d:Datastore {name: "postgresql-primary"}), (t:Team {name: "platform-core"}) MERGE (d)-[:owned_by]->(t);
MATCH (d:Datastore {name: "redis-cache"}), (t:Team {name: "platform-core"}) MERGE (d)-[:owned_by]->(t);
MATCH (d:Datastore {name: "minio-assets"}), (t:Team {name: "platform-core"}) MERGE (d)-[:owned_by]->(t);

MATCH (d:Dependency {name: "litellm-proxy"}), (t:Team {name: "platform-core"}) MERGE (d)-[:owned_by]->(t);
MATCH (d:Dependency {name: "langfuse-tracing"}), (t:Team {name: "platform-core"}) MERGE (d)-[:owned_by]->(t);
MATCH (d:Dependency {name: "presidio-pii"}), (t:Team {name: "platform-core"}) MERGE (d)-[:owned_by]->(t);

MATCH (g:FeatureGate {name: "warehouse-full-inventory-sync"}), (t:Team {name: "warehouse-product"}) MERGE (g)-[:owned_by]->(t);
MATCH (g:FeatureGate {name: "ai-description-lazy-cache"}), (t:Team {name: "ai-team"}) MERGE (g)-[:owned_by]->(t);
MATCH (g:FeatureGate {name: "box-size-beta-ui"}), (t:Team {name: "warehouse-product"}) MERGE (g)-[:owned_by]->(t);

// --- member_of ---
MATCH (p:Person {handle: "a.nowak@example.com"}), (t:Team {name: "platform-core"}) MERGE (p)-[:member_of]->(t);
MATCH (p:Person {handle: "p.warehouse@example.com"}), (t:Team {name: "warehouse-product"}) MERGE (p)-[:member_of]->(t);
MATCH (p:Person {handle: "m.ai@example.com"}), (t:Team {name: "ai-team"}) MERGE (p)-[:member_of]->(t);

// --- exposes (host-app exposes all three endpoints) ---
MATCH (s:Service {name: "host-app"}), (e:Endpoint {path: "/api/products/{id}"}) MERGE (s)-[:exposes]->(e);
MATCH (s:Service {name: "host-app"}), (e:Endpoint {path: "/api/plugins/{id}/objects"}) MERGE (s)-[:exposes]->(e);
MATCH (s:Service {name: "host-app"}), (e:Endpoint {path: "/api/categories"}) MERGE (s)-[:exposes]->(e);

// --- uses_datastore (KEY: postgresql-primary fans-in from 3 services) ---
MATCH (s:Service {name: "host-app"}), (d:Datastore {name: "postgresql-primary"}) MERGE (s)-[:uses_datastore]->(d);
MATCH (s:Service {name: "ai-description"}), (d:Datastore {name: "postgresql-primary"}) MERGE (s)-[:uses_datastore]->(d);
MATCH (s:Service {name: "warehouse"}), (d:Datastore {name: "postgresql-primary"}) MERGE (s)-[:uses_datastore]->(d);
MATCH (s:Service {name: "box-size"}), (d:Datastore {name: "redis-cache"}) MERGE (s)-[:uses_datastore]->(d);
MATCH (s:Service {name: "host-app"}), (d:Datastore {name: "minio-assets"}) MERGE (s)-[:uses_datastore]->(d);

// --- uses_dependency ---
MATCH (s:Service {name: "ai-description"}), (d:Dependency {name: "litellm-proxy"}) MERGE (s)-[:uses_dependency]->(d);
MATCH (s:Service {name: "ai-description"}), (d:Dependency {name: "langfuse-tracing"}) MERGE (s)-[:uses_dependency]->(d);
MATCH (s:Service {name: "ai-description"}), (d:Dependency {name: "presidio-pii"}) MERGE (s)-[:uses_dependency]->(d);

// --- affects (each Revision points at its target) ---
MATCH (r:Revision {id: "rev-001"}), (g:FeatureGate {name: "warehouse-full-inventory-sync"}) MERGE (r)-[:affects]->(g);
MATCH (r:Revision {id: "rev-002"}), (s:Service {name: "ai-description"}) MERGE (r)-[:affects]->(s);
MATCH (r:Revision {id: "rev-003"}), (d:Dependency {name: "litellm-proxy"}) MERGE (r)-[:affects]->(d);
MATCH (r:Revision {id: "rev-004"}), (s:Service {name: "host-app"}) MERGE (r)-[:affects]->(s);
MATCH (r:Revision {id: "rev-005"}), (s:Service {name: "warehouse"}) MERGE (r)-[:affects]->(s);

// --- authored_by ---
MATCH (r:Revision {id: "rev-001"}), (p:Person {handle: "p.warehouse@example.com"}) MERGE (r)-[:authored_by]->(p);
MATCH (r:Revision {id: "rev-002"}), (p:Person {handle: "m.ai@example.com"}) MERGE (r)-[:authored_by]->(p);
MATCH (r:Revision {id: "rev-003"}), (p:Person {handle: "a.nowak@example.com"}) MERGE (r)-[:authored_by]->(p);
MATCH (r:Revision {id: "rev-004"}), (p:Person {handle: "a.nowak@example.com"}) MERGE (r)-[:authored_by]->(p);
MATCH (r:Revision {id: "rev-005"}), (p:Person {handle: "m.ai@example.com"}) MERGE (r)-[:authored_by]->(p);
// Note: rev-005 (warehouse deploy 7d ago) authored by m.ai is intentional background — mixed team contributions

// --- gates (FeatureGate -> Service) ---
MATCH (g:FeatureGate {name: "warehouse-full-inventory-sync"}), (s:Service {name: "warehouse"}) MERGE (g)-[:gates]->(s);
MATCH (g:FeatureGate {name: "ai-description-lazy-cache"}), (s:Service {name: "ai-description"}) MERGE (g)-[:gates]->(s);
MATCH (g:FeatureGate {name: "box-size-beta-ui"}), (s:Service {name: "box-size"}) MERGE (g)-[:gates]->(s);
