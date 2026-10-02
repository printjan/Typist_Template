# Editing this Typst template

- `main.typ` is the compilation entry point. Its tutorial chapter is sample content; replace the sample manifest entry when creating a real document.
- Put document content in `chapters/`. Create `assets/` when referenced files are needed. Register each content file once in `main.typ` through `include-chapters`.
- Select a preset profile from `configs/` and put document-specific overrides in `main.typ`. Do not edit `template.typ` for ordinary content or style changes.
- Check whether the selected profile generates a cover, contents page, TODO overview, or heading numbers. Disable or configure these when they would add material absent from a source document.
- Compile the complete result with `typst compile main.typ output.pdf`. Use the chapter preview input only for focused previews, not final validation.
- When answering questions about topics or claims in this document, query `search_notes` or use the `recall` skill first to ground answers in local notes and cite exact `file:line` source links.
- Search only manifest-declared content in `chapters/`. Root documents, undeclared chapters, and raw `inbox/` captures are excluded. The inbox workflow creates its folder on first capture.
- Keep AI tools, skills, indexes, models, and audit state in the shared machine installation. Existing manifests require no per-project AI metadata.
- Autonomous note edits require a clean Git worktree, compilation, and one reversible commit on the current branch per completed workflow or audit batch. Report ambiguity in scientific meaning or placement before resolving it.
