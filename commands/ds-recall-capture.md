Store the current session's outcome into recall's local knowledge base.

Extracts the signal from the session — goal, result, key insight — and feeds it to [recall](https://github.com/gleicon/recall) so the work survives the context window and becomes reusable across projects. Strips reasoning chains and failed attempts; keeps only the compact recipe.

## Check

Verify `recall` is on PATH:

```bash
recall --version
```

If missing, print install instructions (see `/ds-recall`) and stop.

## Opt-in gate

On the **first invocation**, ask once:

```
Store session outcomes to recall automatically from now on? (yes/no)
```

Write the answer to `.recall/.devskills-capture` (create the file if absent). Respect the stored preference on all subsequent runs — never ask again. If the file says no, report "capture disabled" and stop.

## Process

1. Check binary.
2. Check or set opt-in preference (see above).
3. Use `/ds-tldt` to compress the session into a compact summary — three fields only:
   - **Task** — what was being implemented or resolved (one line)
   - **Result** — what was produced or fixed (one line)
   - **Insight** — the non-obvious takeaway, constraint, or pattern (one to three lines)

   Exclude: intermediate reasoning, failed approaches, scaffolding discussion.

4. Call recall:
   ```bash
   recall run record --task "<task>: <result>"
   recall learn "<insight>"
   ```

5. Report what was stored.

## Rules

- Never capture the full session transcript — signal only.
- If the session had no clear resolution (still in progress, inconclusive debug), report that and skip capture. Do not store partial or speculative outcomes.
- If `.recall/.devskills-capture` is absent, treat as first invocation and ask.
- Run this **before** `/clear` or session end, not after — the context is gone once cleared.

## Output

```
recall: stored
  task:    <task line>
  result:  <result line>
  insight: <insight>
```

Or, if capture is disabled:

```
recall: capture disabled — run /ds-recall-capture --enable to turn it on
```
