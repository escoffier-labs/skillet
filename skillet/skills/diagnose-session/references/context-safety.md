# Reading huge transcripts without losing your context

A single session record can hold a whole conversation history, and one careless print can fill the window of the session doing the diagnosis. These habits are mandatory for the main reader and for any helper.

## Size first

Before opening a file, learn how big it is and where the monsters are:

```bash
wc -lc "$F"                                              # lines and bytes
awk 'length($0) > 100000 { print NR": "length($0) }' "$F"  # line number: length of oversized records
```

## Look at shape, then at a sliver

- Ask for counts and line numbers, not text: `jq -r '.type' "$F" | sort | uniq -c`, or `grep -n 'needle' "$F" | cut -d: -f1`.
- Pull a named field from one numbered line: `sed -n '412p' "$F" | jq -c '{type, timestamp}'`.
- When you must see raw text, cap it: `sed -n '412p' "$F" | cut -c1-500`.
- If any command prints more than about 500 characters for one record, narrow the field or the slice and run it again.
- Do not `cat` a transcript. Do not `grep` it for content without `-c`, `-l`, or a `cut` on the output.

## Let a script do the arithmetic

For totals, groupings, and repeat counts, write a small `jq` or Python script that prints only aggregates and line numbers. Open the handful of lines it points to afterward. Keep scripts and outputs in a scratch directory.

## Never mutate

Session files are evidence. Do not edit, move, or delete them, and do not redact in place.
