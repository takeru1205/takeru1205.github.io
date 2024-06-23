today = $(shell date "+%Y-%m-%d")
year  = $(shell date "+%Y")


dev:
	hugo server --buildDrafts

new:
	hugo new content/posts/$(year)/$(today)/index.md
