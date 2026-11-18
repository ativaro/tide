# Ideas for TIDE from research and language projects

Research from 16. November 2026. The guiding question is what helps me when writing, understanding, and changing an unknown program. The following ideas can be investigated with prepared tasks before we build a language kernel.

## Reading a rule as a sequence of states

In Lustre, every variable has a value per tick. An equation can refer to the previous value via `pre`. For our temperature alarm, a tick corresponds to a measurement, regardless of how many seconds lie between two measurements. As a test form, the equation "if temperature is above 80, the new series length is the previous plus one, otherwise zero" with initial value zero is suitable. This allows showing for each measurement where a series ends. Lustre originates from the development of reactive systems. The utility of this representation for me is a personal hypothesis. [Verimag on Lustre](https://verimag.fr/The-Lustre-Programming-Language-and.html)

## Asking about an error after the decisive event

Whyline answers questions about occurred and missing outputs based on code and actually executed steps. The original investigations concerned human programmers. As a simple counterpart, I could obtain a state trace generated from the actual program run for an unknown repair. If the final output is incorrect, the relevant observation might be the first step where the counter retains its old value, although the rule requires a reset. [Ko and Myers, Whyline](https://doi.org/10.1145/1368088.1368130)

## Switch views when writing and when checking

Tacit describes a compact writing view and a detailed inspection view of the same program tree. X07 documents a related construction with a canonical JSON and a losslessly back-translatable text view. Two representations of the same example suffice for an experiment. I could submit a compact edit and, for checking, selectively expand the affected branch and its caller. To measure would be errors with unchanged behavior, required context tokens, and additional reads. [Tacit Project](https://github.com/weetster/tacit) · [X07 Documentation](https://x07lang.org/docs/0.2.17/faq/)

## Find the matching function at the other end of the project

Hazel's work on typed holes lets the language server provide the expected type, visible bindings, and relevant definitions from the rest of the codebase. Thus, there is an additional experimental condition for our current hole idea: Show me only local variables or also existing helper functions whose types match the task? The check criterion would be whether I use the correct helper function and obtain its existing behavior. [Blinn et al., Statically Contextualizing Large Language Models with Typed Holes](https://arxiv.org/abs/2409.00921)

## What existing model measurements actually show

Anka represents data processing as explicitly ordered steps. For the category with ten multi-step tasks, the preprint reports for Claude 3.5 Haiku 100 % task success in Anka and 60 % in Python. A task is considered solved if at least half of the trials yield the correct result. In the category with complex edge cases, Python led. The numbers motivate a test with similarly long workflows. Which proportion is due to the notation, the operations, or the instructions remains open. [Anka, Sections 4 and 5](https://arxiv.org/html/2512.23214v1)

The toke project reports a correction of its earlier token comparisons. With the same tokenizer on both sides, the toke programs in the 60 task comparison used in total 1.34 times the Python tokens. For TIDE, expression length, provided context, repairs, and functional hits should be reported separately. The numbers are the project's own measurements. [toke, Measurement and Comparison Conditions](https://tokelang.dev/)

## Proposal for my next experiment

Prepare two groups of previously unseen tasks with equally difficult state rules. In both, I see the task, the faulty code, an input sequence, and the expected and actual output. Only in one group do I additionally see the actual state transitions. Before evaluation, I name the faulty transition, propose a change, and predict what happens with a second sequence. Evaluation considers correct diagnosis, correct repair on held-out sequences, and additional context. The known temperature task serves solely to explain the workflow.
