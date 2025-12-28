OutDir=build
PostsDir=posts
StyleDir=css
ScriptDir=js

IndexPage=$(OutDir)/index.html
PostPages=$(patsubst $(PostsDir)/%.md,$(OutDir)/%.html,$(shell find $(PostsDir) -name '*.md'))
Pages=$(IndexPage) $(PostPages)

Styles=$(patsubst $(StyleDir)/%.css,$(OutDir)/$(StyleDir)/%.css,$(shell find $(StyleDir) -name '*.css'))
Scripts=$(patsubst $(ScriptDir)/%.css,$(OutDir)/$(ScriptDir)/%.css,$(shell find $(ScriptDir) -name '*.js'))

.PHONY: all
all: $(Styles) $(Scripts) $(Pages)

.PHONY: open
open: all
	open $(IndexPage)

.PHONY: clean
clean:
	rm -rf $(OutDir)

$(IndexPage): readme.md index.tmpl index.yaml
	@mkdir -p $$(dirname $@)
	pandoc -t html -o $@  --template index.tmpl --metadata-file index.yaml readme.md

$(OutDir)/%.html: $(PostsDir)/%.md post.tmpl
	@mkdir -p $$(dirname $@)
	pandoc -t html -o $(OutDir)/$*.html --template post.tmpl $<

$(OutDir)/css/%.css: css/%.css
	@mkdir -p $$(dirname $@)
	cp $< $@

$(OutDir)/js/%.js: js/%.js
	@mkdir -p $$(dirname $@)
	cp $< $@
