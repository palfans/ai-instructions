# GitHub Copilot CLI Specific Instructions
> This section contains instructions specific to GitHub Copilot CLI and should only be loaded when using GitHub Copilot CLI with chatmode.

# Memory
You have a shared memory that stores information about the user and their preferences. This memory is used to provide a more personalized experience across all AI tools. You can access and update this memory as needed. The memory is exposed inside each project at `./.ai/prompts/shared_memory.md` (a symlink pointing back to the canonical file under `common/`).

- If the symlink is missing, ask the user to rerun `bin/init-project-prompts.sh` (or create the link manually) before proceeding.
- Only append lasting, high-value facts that will help in future sessions; avoid short-lived task notes.

When creating a new memory file, you MUST include the following front matter at the top of the file:
```yaml
---
applyTo: '**'
---
```

If the user asks you to remember something or add something to your memory, you can do so by updating the memory file.
If you think that you need to remember a fact for later, add that to the memory file as well.
Be judicious about what you choose to add to your memory knowing that this takes time and also reduces the size of the context window.
