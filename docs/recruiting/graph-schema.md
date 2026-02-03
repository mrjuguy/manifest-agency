# Knowledge Graph Schema: AI Staffing

**Version:** 1.0
**Purpose:** Enables DeepSeek R1 to perform "Multi-Hop Reasoning" over candidates.
**Database:** Neo4j / FalkorDB

## Why Graph?
Standard SQL/Vector search cannot answer:
> "Find me a candidate who worked at a Fintech startup during a growth phase."

A Graph can:
`Candidate -[WORKED_AT {year: 2024}]-> Company -[IS_A]-> "Fintech" -[STATUS]-> "Series B"`

## Nodes & Properties

### 1. `Candidate`
Represents the human applicant.
- `id`: UUID
- `name`: String
- `total_yoe`: Float
- `resume_summary`: Vector<Embeddings>

### 2. `Company`
Extracted from resume work history.
- `name`: String
- `tier`: ["Tier 1", "Startup", "Agency", "Enterprise"] (Inferred by R1)
- `industry`: String
- `stage`: ["Seed", "Growth", "Public"]

### 3. `Skill`
Canonical skill name (normalized).
- `name`: "React"
- `category`: "Frontend"
- `aliases`: ["React.js", "ReactJS"]

### 4. `JobRole`
Standardized role title.
- `title`: "Senior Software Engineer"
- `level`: ["L3", "L4", "L5", "Staff"]

---

## Relationships (Edges)

### `(:Candidate)-[:WORKED_AT {duration_months: Int, is_current: Bool}]->(:Company)`
Captures tenure.
*Reasoning Pattern:* "Short tenure at 3 consecutive companies = 'Job Hopper' flag."

### `(:Candidate)-[:USED_SKILL {proficiency: Int, last_used: Date}]->(:Skill)`
Captures hard skills.
*Reasoning Pattern:* "Hasn't used Java since 2020 = 'Rusty'."

### `(:Company)-[:BELONGS_TO]->(:Industry)`
Captures domain expertise.
*Reasoning Pattern:* "Worked at Stripe + Plaid = 'Fintech Expert'."

### `(:Company)-[:COMPETES_WITH]->(:Company)`
Captures "Poaching" opportunities.
*Reasoning Pattern:* "Client is Uber. Candidate worked at Lyft. Strong fit."

---

## Sample Cypher Query (Reasoning)

**Goal:** Find a React dev from a top-tier startup who knows Fintech.

```cypher
MATCH (c:Candidate)-[:WORKED_AT]->(comp:Company)
WHERE comp.tier = "Tier 1" AND comp.industry = "Fintech"
MATCH (c)-[:USED_SKILL]->(s:Skill)
WHERE s.name = "React"
RETURN c.name, comp.name, s.proficiency
ORDER BY s.proficiency DESC
```

## Ingestion Pipeline (R1)

1.  **Input:** Resume PDF.
2.  **Extraction:** DeepSeek R1 extracts entities + relationships.
3.  **Normalization:** Map "ReactJS" -> "React" node.
4.  **Enrichment:** Use Proxycurl to fetch Company metadata (Tier, Industry) if unknown.
5.  **Write:** Upsert to GraphDB.
