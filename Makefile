.PHONY: all
all: build sync deploy

.PHONY: build
build: last-modified

.PHONY: last-modified
last-modified: index.template.html
	sed "s/%DATETIME%/$(shell date '+%Y-%m-%dT%H:%M:%S%z')/g" index.template.html > index.html

.PHONY: deploy
deploy:
	scp -r index.html research static newton:/var/www/dhil.net/

.PHONY: sync
sync:
	git add index.html index.template.html
	git add research/ static/
	git commit -m "Sync"
	git push

.PHONY: publish
publish: all sync deploy
