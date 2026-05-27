# Anti-bloat rules

Generated artifacts must map to an execution state and stay smaller than the conversation that produced them.

## Flag patterns

- Multiple implementation options without a chosen path
- Framework language without a named extension axis
- Repeated context that does not change execution
- Missing owner, status, or QA
- Unbounded “future considerations”
- Invented file paths
- Generic acceptance criteria
- Stakeholder claims promoted as fact

## Bloat score (post-generation)

| Signal | Points |
|--------|--------|
| >1 implementation option | +2 |
| Full tier without non-goals | +2 |
| No QA steps | +2 |
| No owner/status | +2 |
| >1200 words (standard) | +1 |
| >500 words (micro) | +1 |
| Vague advisory vocabulary | +1 |
| Single chosen path | -2 |
| Clear DoD | -2 |
| Source references | -1 |

Score ≥ 4 requires compression before saving as an execution artifact.

Implementation: `plugin/workspace_knowledge/execution.py` (`bloat_score`).
