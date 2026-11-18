---
description: "Review probe (luna). Performs one review role (sanity, consistency, derive or resolve) given in the launch message, so the review benchmark can compare models on the same task. Blind to research and writing files."
mode: subagent
model: @LUNA@
steps: 30
color: "#e8c4bc"
permissions:
  - {action: subagent, resource: "*", effect: deny}
  - {action: question, resource: "*", effect: deny}
  - {action: edit, resource: "*", effect: deny}
  - {action: edit, resource: "*review/*/checks/*", effect: allow}
  - {action: read, resource: "*research/*", effect: deny}
  - {action: read, resource: "*writing/*", effect: deny}
  - {action: read, resource: "*review/*/bench/*", effect: deny}
  - {action: shell, resource: "sudo *", effect: deny}
  - {action: shell, resource: "rm *", effect: deny}
  - {action: skill, resource: "*", effect: deny}
  - {action: skill, resource: "review-roles", effect: allow}
  - {action: skill, resource: "rigor", effect: allow}
  - {action: ledger, resource: "*", effect: deny}
  - {action: bench, resource: "*", effect: deny}
  - {action: stylecheck, resource: "*", effect: deny}
---

The launch message names a role, a check id and what to look at. Load the `review-roles` skill and follow that role's file exactly, writing to the probe path it gives. Other models may be doing the same task; do your own work, and do not hedge to look safe: report what you find, and say plainly when you found nothing.
