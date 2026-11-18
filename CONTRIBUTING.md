# Contributing to TIDE

Describe the application task first. Include the TIDE version and source revision, the smallest input or TIDE example that shows the issue, the command you ran, and the expected and observed results. A missing library report can start with the operation your application needs and the workaround you tried.

**For a fix**, include a focused change and an executable TIDE example that fails before the fix and passes afterwards. Run the affected examples. A change to a language rule should cover the supported execution paths it affects and update the language reference. The maintainer checks the relevant regression suite before merging. [Project conventions](AGENTS.md) · [Language reference](LANGUAGE.md)

**For a language or library proposal**, describe the smallest interface that would let the application proceed. Include a short use example, an alternative you considered, and the compatibility impact on existing programs or pins. A working compiler patch is optional at this point.

With access to the private repository, use an issue for a proposal or a pull request for a patch. An offline pilot can keep the proposal in its project notes, or commit a patch and hand the maintainer the output of `git format-patch -1 --stdout > change.patch`. Use a small, shareable example when the application or its input is confidential.

The TIDE maintainer records the decision in the issue, pull request or local pilot record the team can read. Use **accepted**, **needs evidence**, **deferred** or **declined** and give the reason. For missing evidence, name the example or observation needed for review. For accepted work, link the implementing revision when available. The team can reopen the decision with a failing example or changed requirement.
