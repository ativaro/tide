# TIDE

TIDE is a standalone programming language. Its specification defines its syntax, types, evaluation and error handling. Native execution must follow those rules directly.

Write all project documentation in English. This includes specifications, repository guides, plans, experiment reports, and project-authored GitHub descriptions, issues, pull requests and releases. Keep commands, identifiers, recorded measurements and hash-verified study inputs reproducible.

Implement applications, libraries, language extensions and new executable tests in TIDE. When an application needs a capability, add it to TIDE as a reusable feature and use it from the application. A host, adapter or helper process written in another language cannot substitute for a language feature.

Remove Python from the entire TIDE toolchain, including bootstrap, build, execution, testing and interactive hosts. CPython may serve as an external baseline for explicitly requested comparisons. Verify each replacement command with the same inputs and expected results in an environment without Python.

Evaluate language changes against three separate 100× goals: program runtime, model tokens to a correct solution, and time to a successful repair. Measure each independently. [Measurement rules](tasks/plan.md)

## graphify

When the user enters `/graphify`, first use the installed skill at `~/.Codex/skills/graphify/SKILL.md` or follow its instructions.
