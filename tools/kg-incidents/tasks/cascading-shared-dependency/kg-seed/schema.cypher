// schema.cypher — Neo4j constraints and indexes for Operational Topology Graph.
// Run once at container startup before seeding nodes.

// --- Uniqueness constraints ---
CREATE CONSTRAINT service_name IF NOT EXISTS FOR (n:Service) REQUIRE n.name IS UNIQUE;
CREATE CONSTRAINT datastore_name IF NOT EXISTS FOR (n:Datastore) REQUIRE n.name IS UNIQUE;
CREATE CONSTRAINT dependency_name IF NOT EXISTS FOR (n:Dependency) REQUIRE n.name IS UNIQUE;
CREATE CONSTRAINT feature_gate_name IF NOT EXISTS FOR (n:FeatureGate) REQUIRE n.name IS UNIQUE;
CREATE CONSTRAINT revision_id IF NOT EXISTS FOR (n:Revision) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT team_name IF NOT EXISTS FOR (n:Team) REQUIRE n.name IS UNIQUE;
CREATE CONSTRAINT person_handle IF NOT EXISTS FOR (n:Person) REQUIRE n.handle IS UNIQUE;

// --- Indexes for common query patterns ---
CREATE INDEX service_tier IF NOT EXISTS FOR (n:Service) ON (n.tier);
CREATE INDEX datastore_kind IF NOT EXISTS FOR (n:Datastore) ON (n.kind);
CREATE INDEX revision_at IF NOT EXISTS FOR (n:Revision) ON (n.at);
CREATE INDEX revision_target IF NOT EXISTS FOR (n:Revision) ON (n.target);
CREATE INDEX revision_kind IF NOT EXISTS FOR (n:Revision) ON (n.kind);
CREATE INDEX feature_gate_state IF NOT EXISTS FOR (n:FeatureGate) ON (n.state);
