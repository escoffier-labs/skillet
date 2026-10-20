# Blind A/B eval of a skill change

Use when you changed a skill and need evidence the new version is better, not just different. The risk is leakage: if the candidate can tell it is being tested, or the judge can tell which variant is which, the result measures the test and not the skill. Procedure adapted from pstack by Lauren Tan (MIT).

## Blinding rules

- The candidate sees an organic project. No directory, file, prompt, or slug contains words like eval, test, judge, experiment, rubric, score, compare, benchmark, candidate, or variant. Use names a real user would pick.
- The candidate prompt is what a user would type: the goal, with no meta. It does not ask which skills or principles were applied. Ask for design notes in general terms and grade skill-following from the transcript.
- A candidate never learns that other candidates exist.
- The judge may know it is judging. It sees outputs by sanitized label only (for example `alpha` and `bravo`), never a variant or model name.
- One judge scores both variants in a single pass on one scale. Two judges, or two passes, introduce drift you cannot separate from the effect.

## Procedure

1. **Frame.** State the variant under test (old skill versus new) and what behavior counts as success. Write 3 to 6 concrete criteria for the judge. Keep them away from candidates.
2. **Set up plain directories.** One working directory per candidate run, each with its variant of the skill installed where the harness would normally find it, plus any project context an organic task would have (a small source tree, a README). Same prompt for every run. Randomize which label maps to which variant and record the mapping somewhere the judge cannot read.
3. **Run the candidates.** Several runs per variant on the same model, each in its own directory with fresh context. Do not steer a run.
4. **Judge.** Give one judge the criteria and the outputs by sanitized label. It scores each and says which output better meets the criteria, with reasons tied to the criteria.
5. **Grade skill-following from the transcript.** Read each candidate's session transcript from the current project only (never glob across projects; that crosses into unrelated private sessions). List which files it actually opened and which skill it loaded, and compare the code or document shape to what the skill asks for. Judge from what it did, not from what it says it did.
6. **Read every output yourself,** end to end, and compare against the judge. When you and the judge disagree, suspect the rubric first: criteria that are ambiguous or reward the wrong thing produce confident, wrong verdicts. Only then suspect a biased judge.
7. **Decide.** Report: the variant under test, the criteria, per-run notes, the judge's verdict, your synthesis, and whether to promote the change. Note the baseline in the skill's changelog entry.

## Traps

- A candidate prompt that mentions the skill's vocabulary teaches the answer. Write it as a user who has never heard of the skill.
- A directory named after the experiment leaks it through the path in tool output.
- Judging each variant in a separate pass lets the scale drift between them.
- A single run per variant. Variance between runs of the same variant can exceed the effect you are measuring, so repeat before concluding.
- Trusting the candidate's own account of what it followed.
