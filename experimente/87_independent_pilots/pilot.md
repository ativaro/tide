# Run an independent TIDE pilot

Each team chooses a real application it wants to build, owns its source, and defines what success looks like. Use one copy of the record below per team. An alias and local revision IDs are sufficient. The observer records help and blockers, including work the team abandons. The team decides what application evidence it can share.

1. **First working version.** Write down one input and observable result before implementation. Install TIDE in a user-owned prefix, record the tool and application revisions, and save the actual test and run output. Record installation friction and any library the team needed but could not find. [Installation guide](../../GETTING_STARTED.md)
2. **A functional change.** After recording the first version, the team chooses a new behavior it needs. Save an example that exposes the gap in the old application. Record the change, which modules or packages it touched, and whether both old and new examples pass. Keep the first revision available for comparison.
3. **Tool upgrade.** Install the second TIDE revision in a separate prefix. Use a copy of the application with its original lock. Record the first result, any migration and the result with the new tool. Preserve both the original application and its working tool. The application change and tool upgrade have separate outcomes. [Version pins](../../LANGUAGE.md) · [Rehearsed upgrade commands](report.md#reproduce-the-local-check)
4. **Team decision.** Ask each team whether it would voluntarily use TIDE for its next comparable application, and why. Ask whether it could contribute an improvement itself and what it actually tried. If it offers a change, follow it through to a recorded maintainer decision. A team can decline either TIDE or contributing. [Contribution process](../../CONTRIBUTING.md)

### Team record

| Record | Team evidence |
|---|---|
| Team alias, self-selected application and user need | |
| Installation environment, TIDE version and revision, commands and difficulties | |
| First application revision, acceptance input, expected and observed result | |
| Missing libraries, workaround and impact, or none encountered | |
| Requested extension, second application revision, changes and maintenance effort | |
| Original and new example results, failed attempts and help received | |
| Upgrade pins, first diagnostic, required migration and resulting behavior | |
| Would you choose TIDE again? Record the team’s answer and reason. | |
| Could you contribute an improvement yourself? Record the answer, any attempt, and resulting patch or decision. | |
| Completed, stopped or still open; reason and evidence location | |
