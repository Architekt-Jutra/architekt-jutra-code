# Research Methodologies Reference (Gatherer)

Patterns and decision frameworks for research methodology selection in the research-gatherer workflow. This is a gathering-only reference — no synthesis, no modeling, no conclusions.

---

## Research Type Classification

Research-gatherer uses a simplified two-axis classification: **where** the information lives (internal vs external) and whether both are needed (mixed).

### Decision Criteria

**Internal Research**:
- **Keywords**: "how does our system", "what are the requirements", "what problems exist", "what do users say", "how is it implemented", "what's in the codebase", "what tickets describe"
- **Focus**: Information that lives inside the organization's boundaries — code, configuration, documentation, issue trackers, transcripts, meeting notes, internal wikis
- **Primary sources**: Source code, tests, configuration files, Jira/Linear tickets, Confluence/Notion pages, transcripts, internal documentation, PR history
- **Tools**: Glob, Grep, Read, Bash (for codebase); connected integrations for issue trackers and wikis
- **Output emphasis**: Findings grounded in internal evidence with file paths, ticket IDs, and quotes

**External Research**:
- **Keywords**: "best practices", "industry standards", "how others do it", "competitors", "market", "state of the art", "recommended approach", "similar products"
- **Focus**: Information from outside the organization — industry patterns, competitor analysis, framework documentation, standards, academic sources
- **Primary sources**: Web resources, framework documentation, API docs, industry reports, blog posts from recognized experts, standards (OWASP, W3C, RFCs)
- **Tools**: WebSearch, WebFetch
- **Output emphasis**: Cited findings with URLs, authoritative source assessment, applicability notes

**Mixed Research**:
- **Keywords**: Combination of above, or broad questions that span internal and external boundaries
- **Trigger**: Question mentions BOTH internal aspects (our code, our process, our tickets) AND external aspects (competitors, best practices, industry)
- **Focus**: Comprehensive investigation requiring both internal evidence and external context
- **Primary sources**: All applicable sources from both internal and external
- **Tools**: All available tools
- **Output emphasis**: Internal findings cross-referenced with external patterns

### Auto-Detection Rules

```
Research Question Received
         |
         v
Mentions external entities?
(competitors, market, best practices,
 industry, named products, "how others")
         |
    +----+----+
    |         |
   YES        NO
    |         |
    v         v
Also mentions    Only internal?
internal?        (code, tickets,
(our system,     transcripts,
 our process)    our docs)
    |              |
   YES → MIXED    YES → INTERNAL
    |
   NO → EXTERNAL
```

**Self-check after classification** (mandatory):
1. Re-read the research question
2. Ask: "Does answering this FULLY require information from outside the organization?"
3. If yes and type is `internal` → change to `mixed`
4. Ask: "Does answering this require ANY internal sources?"
5. If yes and type is `external` → change to `mixed`

---

## Methodology by Research Type

### Internal Research Methodology

**When to use**: Investigating what exists inside the organization — code, processes, problems, requirements

**Source categories** (gatherer agents align to these):

| Category | What to Look For | Tools |
|----------|-----------------|-------|
| **Codebase** | Implementation patterns, architecture, dependencies, data flows, integration points | Glob, Grep, Read |
| **Documentation** | Project docs, architecture docs, inline comments, READMEs, `.maister/docs/` | Read, Grep |
| **Configuration** | Dependencies, environment setup, infrastructure, CI/CD | Read |
| **Issue tracker** | Tickets, user stories, bug reports, feature requests, comments | Connected integrations (Jira, Linear, GitHub Issues) |
| **Transcripts / meetings** | Stakeholder statements, decisions, concerns, shadow processes | Read (local files) |
| **Wiki / knowledge base** | Process documentation, onboarding docs, runbooks | Connected integrations (Confluence, Notion) |

**Gathering strategy**:
1. **Broad discovery**: Pattern matching, directory scanning, ticket listing
2. **Targeted reading**: Key files, relevant tickets, important transcript sections
3. **Deep dive**: Flow tracing, cross-referencing tickets with code, following decision trails
4. **Verification**: Cross-source checks (does the code match what the ticket says? does the transcript match the docs?)

**Success indicators**:
- All specified internal sources investigated
- Findings have file paths, line numbers, ticket IDs, or timestamps
- Contradictions between sources identified
- Gaps documented (what's missing, what couldn't be verified)

---

### External Research Methodology

**When to use**: Investigating what exists outside the organization — patterns, competitors, standards, best practices

**Source categories**:

| Category | What to Look For | Tools |
|----------|-----------------|-------|
| **Framework docs** | Official documentation for technologies used or considered | WebFetch |
| **Industry standards** | OWASP, W3C, RFCs, ISO, compliance requirements | WebSearch, WebFetch |
| **Competitor analysis** | Features, APIs, pricing, positioning, public documentation | WebSearch, WebFetch |
| **Best practices** | Recognized patterns, expert recommendations, conference talks | WebSearch, WebFetch |
| **Academic / reports** | Research papers, industry reports, benchmarks | WebSearch, WebFetch |

**Gathering strategy**:
1. **Source identification**: Find authoritative sources (prefer official docs over blog posts)
2. **Content extraction**: Read and extract key findings with citations
3. **Comparison**: Compare approaches, features, trade-offs across sources
4. **Applicability notes**: Flag what's relevant to project context vs general knowledge

**Source validation**:
- Is this source authoritative? (official docs > recognized expert > random blog)
- Is this current? (check dates — outdated info is dangerous)
- Is this applicable? (matches project context and constraints)

**Success indicators**:
- Multiple authoritative sources consulted (minimum per success criteria)
- Every finding has a URL and quote
- Trade-offs documented (not just "X is best")
- Applicability assessed against project context

---

### Mixed Research Methodology

**When to use**: Questions spanning internal and external boundaries

**Strategy**: Decompose into internal and external sub-questions, then gather in parallel

**Approach**:
1. **Decomposition**: Split research question into internal aspects and external aspects
2. **Parallel gathering**: Launch internal-focused and external-focused gatherer agents simultaneously
3. **Cross-referencing**: In merge phase, compare what internal sources say vs what external sources say

**Example decomposition**:
- Question: "What problems exist in our booking system and how do competitors handle bookings?"
- Internal: "What problems exist in our booking system?" (code, tickets, transcripts)
- External: "How do competitors handle bookings?" (web research, API docs)

**Success indicators**:
- Both internal and external dimensions covered
- Cross-source verification includes internal-vs-external comparisons
- Gaps identified in both directions (what we don't know internally, what we couldn't find externally)

---

## Source Identification Patterns

### Internal: Codebase Sources

**File pattern generation**:
1. Extract key terms from research question
2. Generate patterns:
   ```
   **/*{term}*.{js,ts,py,java,go,rb,php}
   **/services/{term}*
   **/models/{term}*
   **/controllers/{term}*
   ```

**Test files** (provide usage examples and expected behavior):
- `**/*test*, **/*spec*, tests/**, __tests__/**`

**Configuration**:
- `package.json`, `pom.xml`, `requirements.txt`, `go.mod`
- `config/`, `.config/`, `conf/`
- `docker-compose.yml`, `Dockerfile`, `.github/workflows/`

### Internal: Documentation Sources

**Project documentation**:
- `.maister/docs/**/*.md` — framework documentation
- `docs/**/*.md` — project docs
- `README.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`

**Code documentation**:
- Inline comments, JSDoc, Javadoc, docstrings

### Internal: Connected Integrations

**Issue trackers** (Jira, Linear, GitHub Issues):
- Search by project, label, component, assignee
- Extract: title, description, comments, linked PRs, status transitions
- Useful for: requirement discovery, problem identification, decision history

**Wiki / knowledge base** (Confluence, Notion):
- Search by space, tag, title
- Extract: process descriptions, architecture decisions, onboarding guides
- Useful for: institutional knowledge, documented decisions, process flows

**PR history** (GitHub, GitLab):
- Search by path, author, date range
- Extract: change descriptions, review comments, discussion threads
- Useful for: understanding why code changed, finding undocumented decisions

### External: Web Sources

**Authoritative sources** (prefer these):
- Official framework/library documentation
- Standards bodies (OWASP, W3C, IETF)
- Conference talks from recognized experts

**Secondary sources** (use with caution):
- Technical blogs from recognized authors
- Stack Overflow answers with high votes
- Industry reports

**Avoid or flag**:
- Outdated documentation (check dates)
- AI-generated content without verification
- Sources that don't cite their own evidence

---

## Information Gathering Strategies

### Iterative Deepening

**Phase 1: Broad Discovery** (fast, high-level)
- Glob for relevant files, list tickets, scan directories
- Quick landscape assessment

**Phase 2: Targeted Reading** (moderate depth)
- Read key files, important tickets, relevant transcript sections
- Extract main components and patterns

**Phase 3: Deep Dive** (detailed analysis)
- Trace specific flows, cross-reference tickets with code
- Understand implementation details and decision history

**Phase 4: Verification** (validation)
- Cross-reference findings across source types
- Identify contradictions and gaps

**Adaptation**: Skip or combine phases based on complexity

---

### Multi-Source Triangulation

**Purpose**: Validate findings through independent source types

**Approach**:
1. Gather from source type A (e.g., code)
2. Gather from source type B (e.g., tickets)
3. Gather from source type C (e.g., transcript)
4. Compare: do sources agree?
   - Sources agree → High confidence
   - Partial agreement → Medium confidence
   - Sources disagree → Flag contradiction, investigate

**Example**:
- Code shows reservation blocks a seat immediately
- Ticket says "users complain seats aren't actually blocked"
- Transcript: "sales reps call to block seats, but system doesn't reflect it"
- Conclusion: Contradiction found — code behavior vs user experience diverge

---

## Confidence Scoring

### High Confidence (90-100%)
- Multiple independent sources confirm
- Direct evidence (code, explicit docs, ticket with screenshots)
- No contradictions found

### Medium Confidence (60-89%)
- Single source or indirect evidence
- Inferred from patterns or context
- Minor contradictions or gaps

### Low Confidence (<60%)
- Speculation or assumption
- Contradictory evidence
- No direct confirmation
- Based on a single person's claim without corroboration

---

## Common Pitfalls

| Pitfall | Problem | Mitigation |
|---------|---------|------------|
| **Scope creep** | Research expands beyond original question | Continuously refer back to research brief; document scope expansions |
| **Insufficient evidence** | Claims without proof | Strict citation discipline; mark low-confidence findings |
| **Missing cross-references** | Understanding sources in isolation | Explicitly compare findings across source types in verification |
| **Outdated information** | Relying on old docs or stale tickets | Check timestamps; prioritize recent sources; verify docs match code |
| **Over-confidence** | Stating findings with more certainty than warranted | Use confidence scoring; acknowledge limitations |
| **Hallucinated external data** | AI fabricating competitor features or API details | Every external finding needs a URL; verify with WebFetch |

---

This reference provides patterns and frameworks. Actual execution adapts these to specific research contexts.
