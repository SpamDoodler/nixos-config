# Level L: Lean certificates

`rigor=L` applies to **every substantive claim in scope**, not just headline
theorems. Map each claim ID to a certificate. A single theorem can cover
several claims if the map identifies the corresponding conclusions.
Definitions, conventions and hypotheses are not conclusions to prove; identify
them explicitly and do not hide a claimed result inside a hypothesis. A
heuristic or an empirical observation without a matching formal statement
does not pass L. If only a formal model or a finite computation is certified,
say precisely what that certificate establishes and what remains outside it.

## Certificate and acceptance

1. **Match the statement.** Record `claim ID → .lean file → fully qualified
   declaration`. Compare quantifiers, definitions, domains, hypotheses and
   conclusions against the claim. Check for stronger assumptions, weaker
   conclusions, vacuous hypotheses and circular dependencies. Certify the
   actual claim, not a convenient special case or proxy.
2. **Replay.** Use the workspace's pinned Lean project and its local Nix flake.
   Run its documented check or build, including the certificate source (not
   merely importing a cached `.olean`). For example, when the project exposes
   the needed dev shell, use `nix develop .#<shell> -c lake env lean <file.lean>`
   from the Lean project root. Record the project revision/toolchain, exact
   command, exit status and output. Review leads use approved shell access;
   shell-restricted roles hand the check to an authorized role. Follow the
   normal trust and permission rules before executing workspace code.
3. **Audit the trust boundary.** Run `#print axioms` on each target declaration
   in a check file using the same project. Reject `sorryAx`, an axiom standing
   in for the claim, or unapproved assumptions anywhere in its dependencies.
   Ordinary Lean foundational axioms (`propext`, `Classical.choice`,
   `Quot.sound`) are acceptable by default. Disclose other trusted assumptions
   or compiler-backed proof mechanisms; require explicit user approval before
   accepting them. Successful compilation alone does not clear this audit.
4. **Record the outcome.** `certified` requires statement match, successful
   replay and a cleared axiom audit. Use `missing`, `mismatch`, `rejected`
   (e.g. a proof hole), or `unchecked` (e.g. no usable toolchain or permission)
   otherwise. Report any valid M/P evidence separately, without calling the
   claim L-certified or lowering the requested target. Do not mark an L review
   or research goal complete while an in-scope claim lacks a valid certificate;
   give the blocker and the next action instead.

A submitted certificate can be an existing library theorem if it matches and
the project can replay a Lean declaration that applies it under the claim's
actual hypotheses. During review, keep any checker artifacts in the review
area; do not silently repair the submitted certificate or change the project
toolchain.
