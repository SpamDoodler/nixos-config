---
description: "Show project-wide review stats, or run a planted-error benchmark with /review-bench <path> [slug] [depth=standard]"
agent: review
---

Benchmark request: $ARGUMENTS

If no path is supplied, call `bench review_report`, report coverage and
limitations, and stop. Do not run an experiment.

1. Launch `rv-planter` with the document path and the slug (default: `bench-` plus the file name). Do not read anything under `review/<slug>/bench/`.
2. Run your normal procedure on the planted copy in `review/<slug>/target/`, logging checks and findings as usual. Run the benchmark probes regardless of data mode.
3. After `REPORT.md`, launch `rv-scorer` for the slug.
4. Finish with `bench review_report` and a five-line summary of what it shows.
