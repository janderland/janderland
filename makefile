OUT_DIR=build
POSTS_DIR=posts
CSS_DIR=css
JS_DIR=js

# Non-HTML files copied into build dir.
ASSETS=$(addprefix $(OUT_DIR)/,style.css eighties.css highlight.js fql.js go.js)

# Pages generated from markdown.
POST_PAGES=$(patsubst $(POSTS_DIR)/%.md,$(OUT_DIR)/%.html,$(shell find $(POSTS_DIR) -name '*.md'))

INDEX_PAGE=$(OUT_DIR)/index.html

.PHONY: all
all: $(OUT_DIR) $(ASSETS) $(INDEX_PAGE) $(POST_PAGES)

.PHONY: open
open: all
	open $(INDEX_PAGE)

.PHONY: clean
clean:
	rm -rf $(OUT_DIR)

$(INDEX_PAGE): readme.md index.tmpl index.yaml
	pandoc --no-highlight -t html -o $@ --template index.tmpl --metadata-file index.yaml readme.md

$(OUT_DIR)/%.html: $(POSTS_DIR)/%.md post.tmpl
	pandoc --no-highlight -t html -o $(OUT_DIR)/$*.html --template post.tmpl $<

$(OUT_DIR)/%.css: $(CSS_DIR)/%.css
	cp $< $@

$(OUT_DIR)/%.js: $(JS_DIR)/%.js
	cp $< $@

$(OUT_DIR)/%: %
	cp $< $@

$(OUT_DIR):
	mkdir $@
