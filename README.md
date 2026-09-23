# Typst Technical Document & Cheatsheet Architecture

> **Content attribution:** The document text depicted in this repository was authored by Prof. Jens Albrecht and is published here with his permission. The Typst implementation is licensed separately; see [`LICENSE`](LICENSE).

A modular, profile-driven Typst framework engineered for high-density academic cheatsheets (*Klausur-Notizzettel*) and comprehensive technical summaries (*Zusammenfassungen*).

---

## Compilation & CLI Workflows

Compile the document directly with the Typst compiler:

```bash
# Single compilation to PDF
typst compile main.typ output.pdf

# Continuous compilation / live-reload watcher
typst watch main.typ output.pdf

# Focus the live preview on one declared chapter
typst watch --input chapters=tutorial main.typ preview.pdf

# Open in VS Code with the Typst LSP / Typst Preview extensions:
code .
```

### Focused Chapter Previews

Keep one chapter per file and declare the chapter files once in `main.typ`. The IDs are stable preview names; they do not need to match the visible chapter titles.

```typst
#import "template.typ": conf, include-chapters

// Profile setup and #show rule omitted here for brevity.

#include-chapters((
  (id: "foundations", path: "/chapters/foundations.typ"),
  (id: "algorithms", path: "/chapters/algorithms.typ"),
  (id: "appendix", path: "/chapters/appendix.typ"),
))
```

With no `chapters` input, normal compilation still includes the complete document. Pass one ID to focus the preview, or a comma-separated list to preview several chapters while preserving their manifest order:

```bash
# One chapter
typst watch --input chapters=algorithms main.typ preview.pdf

# Several chapters
typst watch --input chapters=foundations,appendix main.typ preview.pdf

# Explicitly select the complete document
typst watch --input chapters=all main.typ output.pdf
```

Unknown IDs stop compilation and list the available IDs, so a typo cannot silently produce an empty preview. The command-line selection is not stored in the project and therefore never creates a Git change.

For an existing notes repository, pull this template update normally and make the one-time `main.typ` migration from individual `#include` statements to `#include-chapters(...)`. Future selector improvements then arrive with ordinary template updates; each project only maintains its own chapter manifest.

### Automated PDF Artifact

Every push of one or more commits to GitHub triggers `.github/workflows/build-pdf.yml`. The workflow compiles the complete document and uploads `Typist_Template-PDF` to the workflow run for 30 days. It has read-only repository access and never commits the PDF. Local PDFs and the `build/`, `out/`, and `tmp/` directories are ignored by Git.

---

## System Architecture

The repository enforces a decoupled architecture separating structural styling, configuration state, and document content.

```text
Typist_Template/
├── configs/                          # Layout and design token profiles
│   ├── exam_notes_horizontal.typ     # 4-Column A4 Landscape (High-density cheat sheet)
│   └── summary_vertical.typ          # 1-Column A4 Portrait (Technical summary)
├── template.typ                      # Core layout engine, chapter selector, components, and lexer
├── main.typ                          # Document entry point & profile binding
├── chapters/                         # Content modules
│   └── tutorial.typ                  # Feature demonstration chapter
├── snippets/                         # External source files (.c, .cpp, .py, etc.)
├── assets/                           # Static figures, diagrams, and vector assets
└── README.md                         # Architecture specification & user manual
```

### Module Responsibilities

- **`main.typ`**: Root compilation target. Binds a concrete profile from `configs/` and declares the chapter manifest.
- **`template.typ`**: The engine implementation. Houses the chapter preview selector, dynamic multi-column background renderer, AST show rules, callout inheritance logic, custom code highlighting engine, and introspection-based metadata aggregation.
- **`configs/`**: Export standalone Typst dictionaries defining design tokens (geometry, typography, spacing, colors, and badge metadata).

---

## Configuration & Profile Engine

### Predefined Profiles

| Parameter Category         | `exam_notes_horizontal.typ`                     | `summary_vertical.typ`                                     |
| :------------------------- | :---------------------------------------------- | :--------------------------------------------------------- |
| **Primary Use Case**       | Ultra-dense exam cheat sheets / revision sheets | Technical summaries / lecture scripts                      |
| **Orientation & Geometry** | A4 Landscape (`297mm × 210mm`)                  | A4 Portrait (`210mm × 297mm`)                              |
| **Columns & Margins**      | 4 columns, `1.6mm` gap, `3.8mm` margin          | 1 column, `15mm` reading margin                            |
| **Column Rules**           | `0.25pt` vertical separator rules               | None (`0pt`)                                               |
| **Base Typography**        | `4.5pt` body font, `2.0pt` leading              | `10.5pt` body font, `5.25pt` leading                       |
| **Heading Hierarchy**      | Compact (`6.2pt` to `5.0pt`), unnumbered        | Proportional (`20pt` to `14pt`), numbered (`1.1`)          |
| **Decorative Rules**       | Level 1 (`0.4pt`) & Level 2 (`0.2pt`)           | Level 1 (`0.97pt`), Level 2 (`0.44pt`), Level 3 (`0.32pt`) |


### Profile Selection & Override Composition

Profiles are immutable Typst dictionaries. Customization is achieved via dictionary concatenation (`+`), enabling granular overrides without mutating preset files.

#### Binding a Preset Profile in `main.typ`
```typst
#import "template.typ": conf, include-chapters
# select the print profile here
#import "configs/summary_vertical.typ": print-profile

#show: doc => conf(
  profile: print-profile,
  doc,
)

#include-chapters((
  (id: "tutorial", path: "/chapters/tutorial.typ"),
))
```

#### Granular Overrides for Strict Page Budgeting
```typst
#import "template.typ": conf, include-chapters
#import "configs/exam_notes_horizontal.typ": print-profile

// Extend the baseline profile with localized overrides
#let print-profile = print-profile + (
  body-size: 4.2pt,              // Reduce font size to compress layout
  body-leading: 1.8pt,
  paragraph-spacing: 2.2pt,
  column-count: 5,               // Increase density to 5 columns
  column-gap: 1.2mm,
  page-margin: 3.0mm,
  info-fill: rgb("fefce8"),       // Custom theme color for info boxes
)

#show: doc => conf(
  profile: print-profile,
  doc,
)

#include-chapters((
  (id: "tutorial", path: "/chapters/tutorial.typ"),
))
```



---

## Template Engine & Features (`template.typ`)

### Dynamic State Resolution

All layout helper functions in `template.typ` use Typst's reactive `context` mechanism coupled with a module-level state `#let _current-profile = state("_current-profile", default-profile)`. 

When `#show: doc => conf(profile: my-profile, doc)` executes:
1. `conf` injects `my-profile` into `_current-profile`.
2. All nested macros across chapter files (`#info`, `#important`, `#code-box`, `#todo`, etc.) resolve styling from `_current-profile.get()` at evaluation time.
3. No profile parameter passing is required at component call sites.

### Container & Admonition System

Callout boxes use a **3-tier inheritance architecture**:
1. **Tier 1 (Global Defaults)**: Properties prefixed with `box-*` (e.g. `box-radius`, `box-inset-left`, `box-above`).
2. **Tier 2 (Admonition Overrides)**: Properties prefixed with `<type>-*` (e.g. `info-stroke`, `important-fill`) take precedence over Tier 1.
3. **Tier 3 (Call-site Arguments)**: Explicit parameters passed to macro invocations (e.g. `#info(radius: 2mm, fill: yellow)[...]`) override both Tier 1 and Tier 2.

```typst
#import "../template.typ": info, important, positive, negative, remember, quote-box, framed

// Standard callouts
#info[Informational note or background context.]
#info(title: "Theorem 3.1")[Custom titled notice.]
#important[Crucial exam fact or invariant.]
#positive[Advantages, best practices, or valid states.]
#negative[Anti-patterns, edge-case hazards, or warnings.]
#remember[High-priority retention point.]

// Blockquote with attribution
#quote-box(author: "Donald Knuth")[
  Premature optimization is the root of all evil.
]

// Low-level generic container
#framed(
  title: "Custom Boundary",
  stroke: 0.5pt + purple,
  fill: rgb("faf5ff"),
)[
  Arbitrary container contents.
]
```

### Advanced Code Engine & Custom Syntax Lexer

The code rendering engine provides:
- **Zebra Striping**: Alternating line backgrounds (`code-line-odd-bg` and `code-line-even-bg`). If a title bar is present, line coloring automatically shifts phase to maintain contrast against the title background.
- **Dynamic Language Badges**: Positioned in the upper-right corner with automated badge-clearance padding on line 1 to prevent text-badge collisions.
- **Embedded Semantic Lexer**: Built-in line highlighter for RDF/Turtle (`turtle`, `ttl`) and SPARQL (`sparql`, `rq`) supporting prefix declarations, IRIs (`<...>`), prefixed names (`pfx:local`), variables (`?var`), literal datatypes/languages, keywords, and `a` predicates.
- **Imports:** `#import "../template.typ": code-box, code-block, turtle, sparql`

#### Standard block with language label

```
int main() {
    return 0;
}
```

#### SPARQL example: specialization with custom title

```
#sparql(title: "Query 1: Extract Professors")[
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?prof ?name WHERE {
  ?prof a :Professor ;
        rdfs:label ?name .
} LIMIT 10
]
```

#### Inclusion from external snippet file

```
#raw(read("../snippets/beispiel.c"), block: true, lang: "c")
```

---

### Introspection & Automatic TODO Aggregation

The TODO subsystem tracks actionable work items across distributed chapter files without manual indexing.

- **`#todo[Description]`**: Steps an internal counter, writes structured `metadata` into the document graph, renders a labeled reference anchor, and draws an inline notification box.
- **`#render-todo-list()`**: Queries the document AST via `context`, extracts all TODO metadata entries, resolves the nearest enclosing Chapter index (`query(selector(heading.where(level: 1)).before(loc))`), and renders a dotted leader index with hyperlinked targets.

```typst
#import "../template.typ": todo, render-todo-list
// Aggregate all document TODO items into a table of contents
#render-todo-list()
// In-text declaration
#todo[Verify formal proof for lemma 2.4]
```

### Proof & Derivation Environments

For mathematical and logical deductions, `#arrow-list` substitutes bullet glyphs with directional implication arrows (`→`).

```typst
#import "../template.typ": arrow-list

#arrow-list[
  - Precondition: Graph $G = (V, E)$ is bipartite.
  - Implication: Chromatic number $chi(G) <= 2$.
  - Conclusion: Graph contains no odd cycles.
]
```

---

## Using This Repository as an Upstream Template

Each user repository can keep its own `origin` while tracking this repository through a second remote named `template`. This makes template updates available to every user project without mixing up where project-specific changes are pushed.

### Recommended Setup for a New User Repository

- Clone this repository so your project and the template start with shared Git history:

  ```bash
  git clone https://github.com/printjan/Typist_Template.git My_Notes
  cd My_Notes
  git remote rename origin template
  ```

- Create a new, empty repository for your project on GitHub. Do not initialize it with a README, license, or `.gitignore`. Then connect and push the notes repository:

  ```bash
  git remote add origin git@github.com:YOUR-USER/My_Notes.git
  git push -u origin main
  ```

- Use an HTTPS URL instead if preferred:

  ```bash
  git remote add origin https://github.com/YOUR-USER/My_Notes.git
  ```

- Confirm that both remotes are configured:

  ```bash
  git remote -v
  ```

- `origin` is the notes project's repository.
- `template` is this repository and supplies future template updates.

### Pulling Future Template Updates

- Run these commands inside each notes repository whenever template updates should be incorporated:

  ```bash
  git fetch template
  git merge template/main
  git push origin main
  ```

- Git may ask you to resolve merge conflicts when both the notes project and the template changed the same lines. After resolving them, complete the merge and push it to the notes repository.
- When first pulling the focused-preview update, keep the notes project's own chapter files and convert its `main.typ` include list to the manifest shown under **Focused Chapter Previews**. This is a one-time project migration.

### Existing or GitHub-Generated Notes Repositories

- Repositories created with GitHub's **Use this template** button have independent Git history. Add this repository as a remote and allow unrelated histories during the first merge only:

  ```bash
  git remote add template https://github.com/printjan/Typist_Template.git
  git fetch template
  git merge template/main --allow-unrelated-histories
  ```

- Resolve any first-merge conflicts and commit the result. All later updates use the normal update commands without `--allow-unrelated-histories`:

  ```bash
  git fetch template
  git merge template/main
  ```

---

## License

The Typst implementation, automation, and repository documentation are available under the MIT License. The document text authored by Jens Albrecht is published with permission and is excluded from that software license. See [`LICENSE`](LICENSE) for the exact boundary. Content written in downstream notes projects remains under those projects' authors and chosen licenses.
