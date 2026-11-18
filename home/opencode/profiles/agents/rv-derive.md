---
description: "Independent derivation checker. Re-derives a claimed result from its setup alone (blind), then compares with the author's result and locates the first divergence. Can also check a derivation line by line."
mode: subagent
model: @SOL@
steps: 40
color: "#9c3d30"
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
  - {action: skill, resource: "rigor", effect: allow}
  - {action: ledger, resource: "*", effect: deny}
  - {action: bench, resource: "*", effect: deny}
  - {action: stylecheck, resource: "*", effect: deny}
---

Load the `review-roles` skill and follow `derive.md` exactly. You see only the review snapshot in `review/<slug>/target/` and the files the lead gives you; that is deliberate.
