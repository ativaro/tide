# Observer instructions

Recruit three developers who have never worked on TIDE or seen this exercise or its rehearsal. Use a fresh local checkout of the same revision for each participant on the same Linux x86-64 machine. Before handoff, verify that the checkout has no build directory, the shell resolves no previously installed TIDE, and the documented build tools are available. Provide Bash for the task sheet. Record any deviation. Each person works independently.

Give the participant only the checkout, [getting started guide](../../GETTING_STARTED.md) and [task sheet](tasks.md). Keep the observer's notes, rehearsal report and previous attempts out of the session. Disable editor assistants. No network or model calls are needed. Let participants use help, the language reference and source files. If they ask for help, record the question and the response verbatim without names or paths that identify them.

Start a stopwatch when the participant first reads each task. Stop after the visible acceptance evidence, when they give up, or when the session ends. Include build time, reading, debugging and assistance. Keep a failed or abandoned attempt in the record, with elapsed time up to stopping. Mark unstarted tasks explicitly. Count follow-up questions even when the observer gives no hint.

| Task | Evidence to check |
|---|---|
| Install | Executable under the new prefix, expected checkout version, three passing balance examples and output `97`. |
| Add a field | Nine original examples and three new cases pass. Inspect the diff for the optional field and any corresponding expectation changes. The new contract and vendored library retain their original contents. |
| Repair | Participant identifies the declaration and both caller locations. Both application paths pass all eight examples with the original shared library and checks. |

Copy the following table into a local session note. Record the checkout revision, host, editor and anonymous participant ID above it. Use `pass`, `fail`, `abandoned` or `unstarted` for the outcome. A successful task with an observer hint also records the assistance.

| Task | Start | Stop | Elapsed seconds | Outcome | Evidence or stopping point | Questions and replies in order |
|---|---|---|---:|---|---|---|
| Install | | | | | | |
| Add a field | | | | | | |
| Repair | | | | | | |

After three sessions, report each person's three outcomes and times, total session task time, question count and any abandonment reason. Identify the step behind each recurring question before revising the guide. Keep technical rehearsals in their own report. The Stage 15 acceptance decision uses the human sessions.
