# Context safety for session transcripts

One transcript record can exceed a megabyte or embed a whole history. Printing one record can overflow the context of the session doing the diagnosis. Apply these to every file, for every reader, every time.

1. **Measure before reading.**

   ```bash
   wc -lc "$F"
   awk '{ if (length($0) > 100000) print NR, length($0) }' "$F"   # long lines
   ```

2. **Never `cat`, `head` without a width cap, or `grep` for content.** Get line numbers and counts first, then small fields from specific lines:

   ```bash
   grep -n 'pattern' "$F" | cut -d: -f1 | head
   jq -r '.type' "$F" | sort | uniq -c | sort -rn
   sed -n '412p' "$F" | jq -c '{type, timestamp}'
   sed -n '412p' "$F" | cut -c1-500
   ```

3. **Narrow anything over 500 characters.** If a command returns more than that for one record, tighten the field or the slice.
4. **Extract with a script, not by eye.** For counts, groupings, and totals, write a short `jq` or Python script that prints only aggregates and line numbers, then open the few lines it points to.
5. **Read-only.** Never modify, move, or delete a session file. Write extractions to a scratch directory.
