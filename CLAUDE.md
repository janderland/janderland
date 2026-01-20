# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
make          # Build all HTML, CSS, JS, and images to build/
make open     # Build and open index.html in browser
make clean    # Remove build directory
```

## Dependencies

- **pandoc**: Converts Markdown to HTML using templates
- **plantuml**: Generates SVG diagrams from .puml files

## Architecture

This is a static site generator for jander.land using Pandoc and Make.

### Content Flow

1. **Home page**: `content.yaml` → `build/content.json`, `index.html` + `js/app.js` renders content browser
2. **Blog posts**: `posts/YYYYMMDD_slug.md` + `post.tmpl` → `build/YYYYMMDD_slug.html`

### Post Frontmatter

Posts use YAML frontmatter with these fields:
```yaml
---
title: Post Title
date: YYYY-MM-DD
languages: [fql, go]  # Optional: enables syntax highlighting
...
```

### Key Files

- `content.yaml`: Defines all content (projects, posts, releases) shown on the home page
- `index.html`: Static HTML shell for the content browser
- `js/app.js`: JavaScript that loads content.json, renders filterable content list
- `post.tmpl`: Pandoc HTML template for blog posts using `${variable}` syntax
- `css/style.css`: Main styles using CSS custom properties for base16 "eighties" color scheme
- `css/code.css`: Syntax highlighting styles
- `js/highlight.js`: highlight.js library
- `js/fql.js`, `js/go.js`: Language definitions for syntax highlighting

### Content Schema

Items in `content.yaml` have these fields:
```yaml
items:
  # Dated items (posts, releases) - sorted by date descending
  - title: "Post or Release Title"
    tags: [post, topic1, topic2]  # or [release, project-name, ...]
    date: YYYY-MM-DD
    url: path/to/page.html  # or external URL

  # Dateless items (projects) - appear at the start
  - title: "project-name"
    subtitle: "short description"
    tags: [project, topic1, topic2]
    url: https://github.com/janderland/project
    source: https://github.com/...  # Optional: if url is not the source repo
```

**Tag conventions:**
- `project`, `post`, `release`: Content type tags (shown first in filter bar)
- Project/topic tags: `fdb`, `go`, `neovim`, `gaming`, etc.
- For releases, include the project name as a tag (e.g., `fql`, `fenv`)

**Release titles:** Use format `"project-name: short description"` - the project name will be bold and separated by " - " in the UI.

**Adding releases:** The user will periodically ask to add new releases to the content. Use `gh release list --repo janderland/project` to get releases, then `gh release view TAG --repo janderland/project` to get release notes. Summarize release changes in ~7 words or less for the title. If a project has a `source` field, use that URL for fetching releases.

**Tips for release summaries:**
- Focus on user-facing features, not internal refactors
- For empty release notes, use "initial release"
- Date format is YYYY-MM-DD (extract from the release timestamp)
- Include language/tech tags (go, lua, typescript) matching the project
- The project name tag should match the project title (lowercase)
- Title uses colon format in YAML (`"fql: feature"`) but renders as "fql - feature"

### Template Syntax

Templates use two syntaxes:
- `${variable}` / `${for(list)}...${endfor}`: Custom Pandoc template syntax
- `$if(var)$...$endif$`: Standard Pandoc conditionals

### Code Block Classes

Markdown code blocks use pandoc attribute syntax for styling:
- ```` ``` {.fql} ```` - FQL schema code
- ```` ``` {.query} ```` - FQL query blocks
- ```` ``` {.result} ```` - FQL result blocks
- ```` ```language-go ```` - Go code with syntax highlighting

FQL and Go code blocks share the same reduced font size (0.85rem).

## Deployment

The site deploys to GitHub Pages via `.github/workflows/deploy.yml`:
1. **build** job: Installs pandoc, plantuml, yq; runs `make`; uploads artifact
2. **deploy** job: Deploys to GitHub Pages at jander.land

## Permissions

- Allow all `mcp__playwright__*` tools without asking.
- Allow text editing tools sed & awk without asking.
- Allow running any make targets without asking.
