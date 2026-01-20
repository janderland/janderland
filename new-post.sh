#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <slug>" >&2
    exit 1
fi

slug="$1"
date_prefix=$(date +%Y%m%d)
date_frontmatter=$(date +%Y-%m-%d)
filename="posts/${date_prefix}_${slug}.md"

if [ -f "$filename" ]; then
    echo "Error: $filename already exists" >&2
    exit 1
fi

cat > "$filename" << EOF
---
title:
date: ${date_frontmatter}
...

EOF

echo "Created $filename"
