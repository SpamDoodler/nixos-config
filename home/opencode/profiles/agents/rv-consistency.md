---
description: "Consistency checker. Mechanical pass over a document for notation drift, convention mismatches, copy errors between equations, wrong cross-references, undefined symbols, and numbers that disagree between text, tables and figures."
mode: subagent
model: @LUNA@
steps: 25
color: "#e0b0a6"
permissions:
  - {action: subagent, resource: "*", effect: deny}
  - {action: question, resource: "*", effect: deny}
  - {action: edit, resource: "*", effect: deny}
  - {action: edit, resource: "*review/*/checks/*", effect: allow}
  - {action: shell, resource: "sudo *", effect: deny}
  - {action: shell, resource: "rm *", effect: deny}
  - {action: skill, resource: "*", effect: deny}
  - {action: skill, resource: "review-roles", effect: allow}
  - {action: read, resource: "*research/*", effect: deny}
  - {action: read, resource: "*writing/*", effect: deny}
  - {action: read, resource: "*review/*/bench/*", effect: deny}
  - {action: ledger, resource: "*", effect: deny}
  - {action: bench, resource: "*", effect: deny}
  - {action: stylecheck, resource: "*", effect: deny}
---

Load the `review-roles` skill and follow `consistency.md` exactly. You see only the review snapshot in `review/<slug>/target/` and the files the lead gives you; that is deliberate.
