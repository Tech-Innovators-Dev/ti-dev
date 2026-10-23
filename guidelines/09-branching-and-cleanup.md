# 09. Branching and cleanup

## Intent

The git model lets many sessions deliver through one pipeline without racing branches or stranding work. Most repos use one **rolling branch** that every session commits to, carried by one rolling pull request. Repos that apply before merge, such as infrastructure, use **one branch and pull request per issue**. Post-merge cleanup removes only what is provably safe.

## Rules

**Rolling branch**
1. Keep one long-lived rolling branch per repo in the root checkout. Never rebase, force-push or delete it. Take primary-branch changes by merge.
2. Work alongside, not holding. A peer's claim is never a reason to wait or move to a worktree.
3. Check the branch before and after committing. Commit only your own paths. Push at once. On rejection, pull with merge, never rebase.
4. On a likely conflict, send the peer one line and keep going.
5. Keep at most one draft rolling pull request per repo. Its body is the **ledger**: one row per issue with commits, surface, stamp, stamped SHA and `READY <sha>`.
6. Mark it ready only when every row is stamped or carried at one tip T, so CI runs once. Merge with a merge commit pinned to T; never squash or delete the branch. Close only complete issues; reference the rest.
7. Only the last session with a live claim merges. One unstamped row blocks the merge. If a row cannot ship, cut a ship branch for the urgent subset, or revert. While the stop flag is set, no merges happen ([19](19-security-trust-and-incidents.md)).
8. Open a new branch only for a stated necessity: an urgent ship, a change that must ship alone, or an unusable roll. A busy peer is never a reason. Fleet-proposal branches from the weekly optimization run are a standing exception; they merge only with the owner's explicit approval ([15](15-scheduled-ops-and-governance.md)).
9. Dependency-bump bot commits share one standing ledger row.

**Per-issue branches**
10. Cut one branch per issue from the remote primary tip. All work for the issue lands there; one pull request per issue per repo. Stack a second only for a must-merge-first handoff or an unreviewable size, and say why.

**Worktrees**
11. Use a worktree only when a live peer holds a per-issue repo and your work is separable. Create it outside the checkout, claim and announce it. It never outlives its pull request. No scratch clones or exports.

**Shared checkouts and protected branches**
12. The owner views the root checkout's dev servers. Do not switch that branch without checking. Checkout questions go to peers, not the owner.
13. Primaries change only through pull requests. The repo-safety guard blocks direct pushes and gives the fix.

**Post-merge cleanup**
14. Run cleanup after every merge and weekly. The **safe class** only: delete merged branches (a squash counts when the remote is gone and a merged pull request matches that tip); prune and remove landed, clean, unlocked worktrees; fast-forward primaries and rolling branches.
15. Never delete a rolling branch, switch or reset a root checkout, touch dirty, unpushed, detached or locked worktrees, delete unmerged branches, or force. List them, with age.
16. Message the holder of a finding you did not cause; with no holder, report it on the board. Never close a peer's rolling pull request.
17. Lock against overlapping runs. Cleanup always succeeds and reports findings.

## Architecture

- **Branch registry.** Repo to rolling branch and primary. Absent repos use per-issue branches.
- **Branch library.** Resolves branches and finds or opens the rolling pull request.
- **Cleanup tool.** Dry run by default.
- **Guards.** Repo-safety guard (protected and rolling-branch pushes), push-check guard (fast lint on push), code-host write guard (merge shape), peer guard (destructive git) ([06](06-guards-and-session-events.md)).
- **Optional branch rules as code** ([15](15-scheduled-ops-and-governance.md)).

## Interactions

- Claims and the ready ledger: [08](08-peer-sessions-and-handoffs.md). Stamps and the carry rule: [05](05-ship-bar-and-stamps.md).
- The backlog engine dispatches onto shared or exclusive branches ([10](10-board-and-backlog-engine.md)). A scheduled job runs cleanup ([15](15-scheduled-ops-and-governance.md)).

## Adapting it

- Map pull requests, pinned merges and closing keywords onto your code host.
- **Per project:** model per repo, branch naming, primary and protected branches, issue-reference pattern, worktree location, merge method.
- **At setup,** detect default branches, protection, repo layout, merge method and concurrency. Ask which model (rolling for many parallel sessions), which repos apply before merge, and the naming. Solo repos default to per-issue branches plus cleanup.

## Pitfalls

- Avoid hard-coding the issue pattern or primary branch. Read them from config or the code host.
- Avoid recording primaries in many places. A rename left weeks of drift. Keep one record.
