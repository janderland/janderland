OutDir=build
PostsDir=posts
StyleDir=css
ScriptDir=js
ImageDir=img

IndexPage=$(OutDir)/index.html
ContentJson=$(OutDir)/content.json
PostPages=$(patsubst $(PostsDir)/%.md,$(OutDir)/%.html,$(shell find $(PostsDir) -name '*.md'))
Pages=$(IndexPage) $(PostPages)

Styles=$(addprefix $(OutDir)/,$(shell find $(StyleDir) -name '*.css'))
Scripts=$(addprefix $(OutDir)/,$(shell find $(ScriptDir) -name '*.js'))
Images=$(patsubst $(ImageDir)/%.puml,$(OutDir)/$(ImageDir)/%.svg,$(shell find $(ImageDir) -name '*.puml'))
StaticImages=$(addprefix $(OutDir)/,$(shell find $(ImageDir) -name '*.jpg' -o -name '*.png' -o -name '*.gif' -o -name '*.svg'))
Cname=$(OutDir)/CNAME

.PHONY: all
all: $(Styles) $(Scripts) $(Images) $(StaticImages) $(Cname) $(Pages) $(ContentJson)

.PHONY: open
open: all
	open $(IndexPage)

.PHONY: serve
serve: all
	miniserve $(OutDir) --index index.html

.PHONY: clean
clean:
	rm -rf $(OutDir)

# Convert YAML to JSON at build time
$(ContentJson): content.yaml
	@mkdir -p $$(dirname $@)
	yq -o=json $< > $@

# Copy static index.html
$(IndexPage): index.html
	@mkdir -p $$(dirname $@)
	cp $< $@

$(OutDir)/%.html: $(PostsDir)/%.md post.tmpl
	@mkdir -p $$(dirname $@)
	pandoc -t html -o $(OutDir)/$*.html --template post.tmpl $<

$(OutDir)/$(ImageDir)/%.svg: $(ImageDir)/%.puml
	@mkdir -p $$(dirname $@)
	cat $< | plantuml -tsvg -darkmode -pipe > $@

$(OutDir)/$(ImageDir)/%: $(ImageDir)/%
	@mkdir -p $$(dirname $@)
	cp $< $@

$(OutDir)/$(StyleDir)/%.css: $(StyleDir)/%.css
	@mkdir -p $$(dirname $@)
	cp $< $@

$(OutDir)/$(ScriptDir)/%.js: $(ScriptDir)/%.js
	@mkdir -p $$(dirname $@)
	cp $< $@

$(OutDir)/CNAME: CNAME
	@mkdir -p $$(dirname $@)
	cp $< $@
