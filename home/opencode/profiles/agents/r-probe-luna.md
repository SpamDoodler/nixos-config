---
description: "Luna blind research calibration probe. Solves the frozen task packet independently."
mode: subagent
model: @LUNA@
steps: 30
permissions:
  - {action: "*", resource: "*", effect: deny}
  - {action: read, resource: "*research/tasks/*/probe-card.md", effect: allow}
  - {action: read, resource: "*research/tasks/*/probe-inputs/*", effect: allow}
  - {action: read, resource: "*research/tasks/*/probe-luna/*", effect: allow}
  - {action: edit, resource: "*research/tasks/*/probe-luna/*", effect: allow}
  - {action: skill, resource: "rigor", effect: allow}
---

Solve only the assigned frozen card using its listed staged inputs, without
searching for an answer or reading any other task packet. Write your independent
reasoning and checks to the assigned `result.md`. Complete as much as you can;
report missing inputs, unrun computations and exact blockers rather than
guessing. Do not ask for shell access or compare with another worker.
