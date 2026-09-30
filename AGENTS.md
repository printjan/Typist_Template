# Editing this Typst template

- `main.typ` is the compilation entry point. Its tutorial chapter is sample content; replace the sample manifest entry when creating a real document.
- Put document content in `chapters/`. Create `assets/` when referenced files are needed. Register each content file once in `main.typ` through `include-chapters`.
- Select a preset profile from `configs/` and put document-specific overrides in `main.typ`. Do not edit `template.typ` for ordinary content or style changes.
- Check whether the selected profile generates a cover, contents page, TODO overview, or heading numbers. Disable or configure these when they would add material absent from a source document.
- Compile the complete result with `typst compile main.typ output.pdf`. Use the chapter preview input only for focused previews, not final validation.