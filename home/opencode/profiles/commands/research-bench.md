---
description: "Detailed research benchmark; /research-bench label <task_id> good|bad [tier]"
agent: research
---

Arguments: $ARGUMENTS

For `label`, call `bench label` with the supplied task ID, label and optional
tier. Otherwise call `bench report`. Distinguish assigned first-try success
from probe success, pending V4 gates from cleared results, and checker
agreement from independent human labels. Give counts and avoid proposing
routing weight changes from sparse data.
