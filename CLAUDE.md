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

1. **Home page**: `readme.md` + `index.tmpl` + `index.yaml` → `build/index.html`
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

- `index.yaml`: Defines the posts list shown on the home page (must be manually updated when adding posts)
- `index.tmpl` / `post.tmpl`: Pandoc HTML templates using `${variable}` syntax
- `css/style.css`: Main styles using CSS custom properties for base16 "eighties" color scheme
- `css/code.css`: Syntax highlighting styles
- `js/highlight.js`: highlight.js library
- `js/*.js`: Language definitions (fql.js, go.js) and initialization

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
1. **docker** job: Builds/pushes container image to GHCR (only when Dockerfile changes)
2. **build** job: Uses the container to run `make`, uploads artifact
3. **deploy** job: Deploys to GitHub Pages at jander.land

To test locally with Docker:
```bash
docker build -t janderland .
docker run --rm -v "$(pwd)":/site janderland make clean all
```

## Permissions

- Allow all `mcp__playwright__*` tools without asking.
- Allow text editing tools sed & awk without asking.
- Allow running any make targets without asking.
