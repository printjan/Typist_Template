# AI notes workflow roadmap

This is the implementation plan for adding AI support to the upstream Typst
template and making it work with every existing and future instance. The plan
targets GitHub Copilot in a local VS Code based editor first. It is a planning
document; none of these features are implemented yet.

## Agreed TODOs

- [ ] Build a local MCP server backed by a full, incrementally updated index of
      all configured template instances. Combine exact and semantic search.
      Return source excerpts with collection, chapter, heading, file, and line
      range. The index must work with both independent and nested Git layouts.
- [ ] Add a short **`place`** workflow: take a rough note, find likely insertion
      points, explain the choices and nearby overlap, and propose a Typst edit.
- [ ] Add a short **`recall`** workflow: answer a question from the notes with
      links to the passages used and make conflicting statements visible.
- [ ] Add a **`review`** workflow for a selected section or complete chapter.
      Cover every subsection and give a navigable overview of central ideas,
      definitions, discussion points, arguments, examples, stated open
      questions, and unresolved TODOs. Provide enough source links to let the
      user judge gaps; do not generate a speculative gap assessment.
- [ ] Add an **`overlap`** workflow that audits all relevant sections, finds
      candidate repetitions and contradictions, and judges them in their full
      scientific context. Distinguish duplicated claims from intentional
      repetition, narrower or broader claims, and merely related ideas.
      Propose reviewable merges or moves. Ask the user concise, batched
      questions when the correct meaning or placement is uncertain.
- [ ] Add a lightweight **`inbox`** for rough, unstructured notes from meetings
      and brainstorming. Preserve the raw capture while the assistant extracts
      items, improves wording, suggests destinations, and proposes edits.
- [ ] Add a source-grounded **`study`** workflow or skill that creates practice
      questions, checks answers against the notes, and points back to the
      relevant passages. Spaced review or Anki export can be considered later.
- [ ] Package the MCP server and lowercase Copilot workflows in the upstream
      template project, install them once per machine, and provide a migration
      path for every already-created template instance.

## Instance detection and indexing

A notes collection is a Typst document root identified by its `main.typ`
chapter manifest, regardless of where a `.git` directory sits. Both layouts
must work:

- A project folder contains sibling `notes/` and `code/` repositories, with
  `main.typ` inside `notes/`.
- One project repository contains `main.typ` at its root or inside a nested
  notes folder, alongside other project files.

The user registers individual notes roots or parent folders once per machine.
The indexer discovers candidate template instances below them and displays an
inclusion list. The chapter manifest establishes the document root and
canonical chapter order. The index includes those chapter files and any
configured `inbox`; other files in `chapters/` are reported for opt-in so
genuine notes outside the manifest are not silently missed. Template
implementation, layout configs, generated PDFs, and unrelated source files
are excluded by default. Nested Git repositories do not affect collection
detection. Canonical paths prevent a collection found through two registered
parents from being indexed twice. A heavily customized fork whose manifest
cannot be recognized needs an explicit project mapping during migration.

Each collection needs a stable identifier and optional display name. The
upstream template must not contain a shared hardcoded project identifier;
the installer can create instance-specific metadata during migration.

The local index stores heading hierarchy, section and paragraph text, TODOs,
source file spans, surrounding context, and exact and semantic search data.
Use Typst document queries for heading and TODO structure and Typst-aware
source parsing for editable file locations. Reindex changed files by content
hash. Keep the index cache local to each machine; rebuild it from the synced
source repositories when necessary.

## One server, deterministic scope

Install one local MCP server per machine for all included collections. It
should start with read-only tools such as `list_collections`, `resolve_scope`,
`search_notes`, `read_section`, `list_sections`, `list_todos`, and
`index_status`. The server returns source locations and enough context for
Copilot to judge a result. The editor agent, not the server, performs note
rewrites through normal file edits and reviewable Git diffs.

Collection resolution must follow this order:

1. An explicitly named collection wins.
2. If the active file is inside a notes collection, use that collection.
3. If the active workspace is a code repository, use an explicitly registered
   project association to its sibling notes repository, or a unique notes
   collection inside the same project folder.
4. If multiple collections still fit, show them and ask the user to choose.

`place`, `review`, `overlap`, and `inbox` must resolve one destination before
writing. `recall` may search all included collections unless scoped. Copilot
does not have to choose among several per-template MCP servers. Its workflow
passes the active file or workspace path to `resolve_scope`; if Copilot cannot
reliably expose that path through its normal workspace tools, add a small
VS Code command or extension bridge to pass it explicitly. Until that bridge
exists, the user selects a collection when automatic resolution is uncertain.
Never silently write to a guessed collection.

The optional `context` workflow combines code or selected text from the
active editor workspace with retrieved passages from the notes index. The
server does not need to index every code repository. If the active code
project is elsewhere or has more than one related notes collection, use the
registered association or an explicit selection.

## Copilot model boundary

GitHub Copilot's selected model handles explanation, placement, review,
scientific comparison, and study questions. The MCP server supplies the
search index and deterministic tools; it does not assume it can invoke the
model selected inside Copilot as a background API. Semantic indexing therefore
uses a local embedding model on each machine, with exact search alongside it.
This design does not require a second hosted language-model account. Retrieved
note passages are still sent to the selected Copilot model during a request.

`review` and `overlap` require full coverage of the chosen scope. Search alone
returns likely matches and can miss material. `review` should enumerate every
section and report which sections were processed. `overlap` should generate
candidates for every section using exact and semantic similarity, then have
Copilot inspect candidate pairs in manageable batches with their surrounding
paragraphs and section context. It must consider heading hierarchy,
definitions, assumptions, method, evidence, citations, and whether a claim is
qualified or scoped differently. A repeated sentence in an introduction and a
formal result can serve different purposes. The report should link both
locations and explain the contextual reason for each proposed action. Large
audits should save progress locally so a Copilot session can resume.

The `inbox` should accept one quick, uncompiled capture file per meeting or
brainstorming session, with a date and optional subject. Processing should
separate facts, decisions, questions, and TODOs; keep a link to the raw capture
for every proposed polished note; and mark items processed only after they
have a destination or a deliberate decision to leave them in the `inbox`.

For note changes, preserve the original passage and show a Git diff. Exact
repetition in the same context may permit a routine edit with validation.
Semantic merges, deletions, and disagreements need specific evidence and a
user decision when intent is unclear. Avoid a fixed model-confidence cutoff
for automatic deletion; confidence should be checked against examples before
it controls actions.

## Delivery to existing and future instances

Develop and version the MCP/indexer package and lowercase workflow skills in
the upstream template project. Install that shared package and its Copilot
skills once per machine at user level. This makes the tools available from a
notes repository, a sibling code repository, or a larger project workspace.
It also avoids running a different server copy from every template fork.

The upstream template should include the source and release process for that
package, documentation, an optional per-instance metadata schema, and the
`inbox` convention. Newly created instances inherit these conventions.
Existing instances can be indexed immediately if their `main.typ` manifest is
recognizable; a path-aware migration tool adds the new per-instance files and
checks that Typst still compiles. It must preview changes before applying
them and leave project content untouched unless migration requires a fix.

Updating the original template files in every old instance remains a Git
rollout task. Clones sharing upstream history can use the existing template
remote merge workflow. Independent GitHub template copies need their own
first-merge or patch path. Instances nested inside a larger repository need
path-aware updates rather than a root-level Git merge. Inventory the actual
instances and their Git histories before automating these updates. On each
machine, install the shared tooling and rebuild a local index from available
notes sources; Git or file sync carries source content, not the index cache.

## Suggested build order

1. Inventory representative instances of both folder layouts and their Git
   relationships. Define collection IDs and any sibling-repository mappings.
2. Implement manifest-based discovery, complete section/TODO extraction,
   local exact and semantic indexing, and source-linked search. Test that
   nested Git boundaries do not change results.
3. Package the read-only MCP server and connect it to local GitHub Copilot.
   Test `resolve_scope` from a notes workspace, a sibling code workspace, a
   single-repository workspace, and an ambiguous workspace.
4. Install the lowercase skills at user level. Implement `place`, `recall`,
   `review`, and the `inbox` processing loop with source-linked output and
   reviewable edits.
5. Implement context-aware `overlap` auditing and `study`. Test full-scope
   coverage and resumability on a large real notes collection.
6. Publish the upstream template update and migration tool. Roll it out to
   inventoried instances with a dry run, Typst compilation, and a Git diff
   for each instance.

## Decisions still needed

- Where the downstream subject and project notes repositories live on each
  machine, and which of them should be indexed.
- Which sibling code and notes repositories belong to the same project when
  their relationship cannot be inferred uniquely from their parent folder.
- Whether the `inbox` should be one shared folder or scoped to each repository.
- How much autonomy to allow for routine note edits after reviewing examples.
- Whether project-context retrieval should become its own `context` workflow.
- Which existing forks share template Git history and which need a path-aware
  migration or update.
