FROM maven:3.8-eclipse-temurin-17

RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    jq \
    ca-certificates \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Python MCP dependencies
RUN pip3 install mcp neo4j

# Neo4j Community 5.15
ENV NEO4J_VERSION=5.15.0
RUN wget -q "https://dist.neo4j.org/neo4j-community-${NEO4J_VERSION}-unix.tar.gz" \
    && tar -xzf "neo4j-community-${NEO4J_VERSION}-unix.tar.gz" -C /opt \
    && mv "/opt/neo4j-community-${NEO4J_VERSION}" /opt/neo4j \
    && rm "neo4j-community-${NEO4J_VERSION}-unix.tar.gz"

# Configure Neo4j: disable auth, bind localhost, tune for small graph
RUN echo "dbms.security.auth_enabled=false" >> /opt/neo4j/conf/neo4j.conf \
    && echo "server.default_listen_address=127.0.0.1" >> /opt/neo4j/conf/neo4j.conf \
    && echo "server.memory.heap.initial_size=256m" >> /opt/neo4j/conf/neo4j.conf \
    && echo "server.memory.heap.max_size=256m" >> /opt/neo4j/conf/neo4j.conf \
    && echo "server.memory.pagecache.size=128m" >> /opt/neo4j/conf/neo4j.conf

WORKDIR /app
COPY . /app

# Copy task-scoped artifacts to a stable location outside /app (which may be rewritten by the agent)
RUN cp -r /app/tools/kg-incidents/tasks/cascading-shared-dependency/kg-seed /opt/kg-seed \
    && cp -r /app/tools/kg-incidents/tasks/cascading-shared-dependency/mcp-seeds /opt/mcp-seeds \
    && cp -r /app/tools/kg-incidents/tasks/cascading-shared-dependency/mcp-servers /opt/mcp-servers \
    && cp /app/tools/kg-incidents/tasks/cascading-shared-dependency/environment/entrypoint.sh /opt/entrypoint.sh \
    && chmod +x /opt/entrypoint.sh

# Reinitialize git inside /app so agent can commit (remove any .git inherited
# from build context, then init fresh with a single "initial" commit).
RUN rm -rf /app/.git \
    && git -C /app init -q \
    && git -C /app config user.email "eval@nasde" \
    && git -C /app config user.name "nasde" \
    && git -C /app add -A \
    && git -C /app commit -m "initial" -q

# Warm the Maven dependency cache so the agent doesn't wait on first build
RUN mvn dependency:resolve -q || true

ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["/bin/bash"]
