.PHONY: all
all: last-modified

.PHONY: last-modified
last-modified: index.template.html
	sed "s/%DATETIME%/$(date '+%Y-%m-%dT%H:%M:%S%z')/g" index.template.html > index.html
