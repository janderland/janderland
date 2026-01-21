#!/bin/bash
set -euo pipefail

# Generate RSS feed from content.yaml
# Includes only items with 'blog' or 'release' tags that have dates

BASE_URL="https://jander.land"

# Output RSS header
cat <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>jander.land</title>
    <link>https://jander.land</link>
    <description>posts and releases from jander.land</description>
    <atom:link href="https://jander.land/rss.xml" rel="self" type="application/rss+xml"/>
EOF

# Process items: filter by tag (blog or release) and must have date
# Sort by date descending, output as tab-separated values
yq '[.items[] | select(.date) | select(.tags | any_c(. == "blog" or . == "release"))] | sort_by(.date) | reverse | .[] | [.title, .url, .date] | @tsv' content.yaml | \
while IFS=$'\t' read -r title url date_iso; do
    # Convert relative URLs to absolute
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="${BASE_URL}/${url}"
    fi

    # Convert YYYY-MM-DD to RFC 822 format
    if [[ "$OSTYPE" == "darwin"* ]]; then
        pub_date=$(date -j -f "%Y-%m-%d" "$date_iso" "+%a, %d %b %Y 00:00:00 GMT" 2>/dev/null || echo "$date_iso")
    else
        pub_date=$(date -d "$date_iso" "+%a, %d %b %Y 00:00:00 GMT" 2>/dev/null || echo "$date_iso")
    fi

    # Escape XML special characters in title
    title_escaped=$(echo "$title" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

    cat <<EOF
    <item>
      <title>${title_escaped}</title>
      <link>${url}</link>
      <guid>${url}</guid>
      <pubDate>${pub_date}</pubDate>
    </item>
EOF
done

# Output RSS footer
cat <<'EOF'
  </channel>
</rss>
EOF
