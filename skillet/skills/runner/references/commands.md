# runner command recipes

GitHub CLI forms. Substitute `<n>`, `<owner>/<repo>`, and branch names. On another forge, use its equivalent and say which one you used.

## Read state

```bash
gh pr view <n> --json state,isDraft,baseRefName,headRefOid,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup
gh pr checks <n> --required          # required checks only
gh pr checks <n>                     # all checks, including optional external ones
gh pr diff <n> --name-only           # files the PR touches
```

`mergeStateStatus` of `DIRTY` means conflicts, `BEHIND` means the base moved, `BLOCKED` means a gate is open (review, required check, or protection rule), `CLEAN` means mergeable.

Unresolved review threads:

```bash
gh api graphql -f query='
query($owner:String!,$repo:String!,$n:Int!,$cursor:String){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$n){
      reviewThreads(first:100, after:$cursor){
        pageInfo{ hasNextPage endCursor }
        nodes{ id isResolved isOutdated path line
          comments(first:20){ nodes{ databaseId author{login} body commit{oid} } } }
      }
    }
  }
}' -f owner=<owner> -f repo=<repo> -F n=<n>
```

When `hasNextPage` is true, repeat with `-f cursor=<endCursor>` added; report partial data if you cannot finish. The comment `databaseId` and `commit.oid` are what you need to reply and to see which head a comment was made on.

## Classify CI

```bash
gh run list --branch <head-branch> --limit 5 --json databaseId,conclusion,headSha
gh run view <run-id> --log-failed | tail -n 80       # real failure text
git fetch origin <base>
git merge-base --is-ancestor origin/<base> HEAD && echo "up to date" || echo "stale base"
git diff --name-only origin/<base>...HEAD            # does the failing code appear here?
```

If the failing test or file is not in the diff and the base is stale, rebase your own branch (or report) before any retry. One fresh run for a flake: `gh run rerun <run-id> --failed`, once.

## Reply from a file

Keep reply files outside the worktree so they cannot be committed. Write the reply text there with your editor tool, then build the JSON with `jq` so the text stays data:

```bash
D="$(mktemp -d)"                       # scratch dir outside the checkout
# write the reply text to "$D/reply.md" with the editor tool, then:
jq -n --rawfile body "$D/reply.md" '{body: $body}' > "$D/payload.json"
gh api --method POST "repos/<owner>/<repo>/pulls/<n>/comments/<comment-id>/replies" --input "$D/payload.json"
rm -rf "$D"
```

`<comment-id>` is the thread's first comment `databaseId`. Replying inside the inline thread keeps the fix next to the finding. Resolve only a thread you have addressed:

```bash
gh api graphql -f query='mutation($id:ID!){ resolveReviewThread(input:{threadId:$id}){ thread{ isResolved } } }' -F id=<thread-node-id>
```

## Waiting

```bash
gh pr checks <n> --watch --interval 30     # exits when checks settle
```

Prefer a CI wait command, a timer unit, or the harness's own wake-up when the wait is long. Re-read the PR when the watcher returns, because threads and mergeability can change while checks run.
