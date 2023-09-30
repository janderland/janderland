pandoc \
  -st html \
  -o index.html \
  --section-divs \
  --css jander.css \
  --metadata title="jander.land" \
  readme.md
