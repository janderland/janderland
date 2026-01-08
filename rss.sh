#!/bin/bash
# Generate RSS 2.0 feed from blog posts

set -euo pipefail

POSTS_DIR="${1:-posts}"
SITE_URL="${2:-https://jander.land}"
SITE_TITLE="jander.land"
SITE_DESC="I think and write"

# XML escape function
xml_escape() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g'
}

# RFC 822 date format for RSS (handles both macOS and Linux)
rfc822_date() {
    local date_str="$1"
    # Try macOS date command first
    if date -j -f "%Y-%m-%d" "$date_str" "+%a, %d %b %Y 00:00:00 +0000" 2>/dev/null; then
        return
    fi
    # Fall back to Linux date command
    if date -d "$date_str" "+%a, %d %b %Y 00:00:00 +0000" 2>/dev/null; then
        return
    fi
    # If both fail, return a default
    echo "Mon, 01 Jan 2020 00:00:00 +0000"
}

# Extract title from YAML frontmatter
get_title() {
    local file="$1"
    awk '/^---$/,/^\.\.\.$/{ if(/^title:/) {sub(/^title: */, ""); print; exit} }' "$file"
}

# Extract date from YAML frontmatter
get_date() {
    local file="$1"
    awk '/^---$/,/^\.\.\.$/{ if(/^date:/) {sub(/^date: */, ""); print; exit} }' "$file"
}

# Extract description from YAML frontmatter (if present)
get_description() {
    local file="$1"
    awk '/^---$/,/^\.\.\.$/{ if(/^description:/) {sub(/^description: */, ""); print; exit} }' "$file"
}

# Get first paragraph after frontmatter as fallback description
get_first_paragraph() {
    local file="$1"
    awk '
        BEGIN { in_frontmatter=0; after_frontmatter=0; found_content=0 }
        /^---$/ { in_frontmatter=1; next }
        /^\.\.\./ && in_frontmatter { in_frontmatter=0; after_frontmatter=1; next }
        after_frontmatter && /^$/ { next }
        after_frontmatter && !found_content && /[[:alnum:]]/ {
            found_content=1
            line = $0
            # Continue reading until blank line
            while (getline > 0 && $0 !~ /^$/) {
                line = line " " $0
            }
            print line
            exit
        }
    ' "$file" | head -c 300
}

# Start RSS document
cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>$(xml_escape "$SITE_TITLE")</title>
    <link>$SITE_URL/</link>
    <description>$(xml_escape "$SITE_DESC")</description>
    <language>en-us</language>
    <lastBuildDate>$(date "+%a, %d %b %Y %H:%M:%S %z")</lastBuildDate>
    <atom:link href="$SITE_URL/feed.xml" rel="self" type="application/rss+xml"/>
EOF

# Process each post (sorted by filename descending for newest first)
for post in $(find "$POSTS_DIR" -name '*.md' -type f | sort -r); do
    filename=$(basename "$post" .md)

    # Extract metadata
    title=$(get_title "$post")
    date=$(get_date "$post")
    description=$(get_description "$post")

    # If no description in frontmatter, use first paragraph
    if [ -z "$description" ]; then
        description=$(get_first_paragraph "$post")
    fi

    # Skip posts without required metadata
    if [ -z "$title" ] || [ -z "$date" ]; then
        continue
    fi

    # Generate item
    cat << EOF
    <item>
      <title>$(xml_escape "$title")</title>
      <link>$SITE_URL/$filename.html</link>
      <guid>$SITE_URL/$filename.html</guid>
      <pubDate>$(rfc822_date "$date")</pubDate>
      <description>$(xml_escape "$description")</description>
    </item>
EOF
done

# Close RSS document
cat << EOF
  </channel>
</rss>
EOF
