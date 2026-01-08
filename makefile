OutDir=build
PostsDir=posts
StyleDir=css
ScriptDir=js
ImageDir=img

IndexPage=$(OutDir)/index.html
PostPages=$(patsubst $(PostsDir)/%.md,$(OutDir)/%.html,$(shell find $(PostsDir) -name '*.md'))
Pages=$(IndexPage) $(PostPages)

Styles=$(addprefix $(OutDir)/,$(shell find $(StyleDir) -name '*.css'))
Scripts=$(addprefix $(OutDir)/,$(shell find $(ScriptDir) -name '*.js'))
Images=$(patsubst $(ImageDir)/%.puml,$(OutDir)/$(ImageDir)/%.svg,$(shell find $(ImageDir) -name '*.puml'))
Cname=$(OutDir)/CNAME

.PHONY: all
all: $(Styles) $(Scripts) $(Images) $(Cname) $(Pages)

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

$(OutDir)/$(ImageDir)/%.svg: $(ImageDir)/%.puml
	@mkdir -p $$(dirname $@)
	cat $< | plantuml --svg --dark-mode --pipe > $@

$(OutDir)/$(StyleDir)/%.css: $(StyleDir)/%.css
	@mkdir -p $$(dirname $@)
	cp $< $@

$(OutDir)/$(ScriptDir)/%.js: $(ScriptDir)/%.js
	@mkdir -p $$(dirname $@)
	cp $< $@

$(OutDir)/CNAME: CNAME
	@mkdir -p $$(dirname $@)
	cp $< $@
