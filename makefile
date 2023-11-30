OutDir=site
PostsDir=posts
ImagesDir=images

PostPages=$(patsubst $(PostsDir)/%.md,$(OutDir)/%.html,$(shell find $(PostsDir) -name '*.md'))
Pages=$(OutDir)/index.html $(PostPages)

.PHONY: all
all: $(OutDir) $(OutDir)/style.css $(OutDir)/index.html $(PostPages)

.PHONY: open
open: all
	open $(OutDir)/index.html

.PHONY: clean
clean:
	rm -rf $(OutDir)

$(OutDir)/index.html: readme.md index.tmpl
	pandoc -t html -o $@ --template index.tmpl --metadata title="jander.land" $<

$(OutDir)/%.html: $(PostsDir)/%.md post.tmpl
	pandoc -t html -o $@ --template post.tmpl --metadata title="$*" $<

$(OutDir)/style.css: style.css
	cp $< $@

$(OutDir):
	mkdir $@
