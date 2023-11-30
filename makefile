OutDir=build
PostsDir=posts

IndexPage=$(OutDir)/index.html
PostPages=$(patsubst $(PostsDir)/%.md,$(OutDir)/%.html,$(shell find $(PostsDir) -name '*.md'))
Pages=$(IndexPage) $(PostPages)

.PHONY: all
all: $(OutDir) $(OutDir)/style.css $(Pages)

.PHONY: open
open: all
	open $(IndexPage)

.PHONY: clean
clean:
	rm -rf $(OutDir)

$(IndexPage): $(Metadata) readme.md index.tmpl
	pandoc -t html -o $@ --template index.tmpl --metadata-file md.yaml $<

$(OutDir)/%.html: $(PostsDir)/%.md post.tmpl
	pandoc -t html -o $@ --template post.tmpl --metadata title="$*" $<

$(OutDir)/style.css: style.css
	cp $< $@

$(OutDir):
	mkdir $@
