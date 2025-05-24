DOCKER := $(shell { command -v podman || command -v docker; })
TIMESTAMP := $(shell date -u +"%Y%m%d%H%M")
COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null)
ifeq ($(shell uname),Darwin)
SELINUX1 :=
SELINUX2 :=
else
SELINUX1 := :z
SELINUX2 := ,z
endif

.PHONY: all left clean_firmware clean_image clean move

all:
	$(shell bin/get_version_local.sh clique >> /dev/null)
	$(DOCKER) build --tag zmk --file Dockerfile .
	$(DOCKER) run --rm -it --name zmk \
		-v $(PWD)/firmware:/app/firmware$(SELINUX1) \
		-v $(PWD)/config:/app/config:ro$(SELINUX2) \
		-e TIMESTAMP=$(TIMESTAMP) \
		-e COMMIT=$(COMMIT) \
		-e BUILD_RIGHT=true \
		zmk
	git checkout config/version.dtsi

left:
	$(shell bin/get_version_local.sh clique >> /dev/null)
	$(DOCKER) build --tag zmk --file Dockerfile .
	$(DOCKER) run --rm -it --name zmk \
		-v $(PWD)/firmware:/app/firmware$(SELINUX1) \
		-v $(PWD)/config:/app/config:ro$(SELINUX2) \
		-e TIMESTAMP=$(TIMESTAMP) \
		-e COMMIT=$(COMMIT) \
		-e BUILD_RIGHT=false \
		zmk
	git checkout config/version.dtsi

clean_firmware:
	rm -f firmware/*.uf2

clean_image:
	$(DOCKER) image rm zmk docker.io/zmkfirmware/zmk-build-arm:stable

clean: clean_firmware clean_image

move:
	@if [ -d "/volumes/ADV360PRO" ]; then \
		LATEST_LEFT=$$(ls -t firmware/*-left-clique.uf2 2>/dev/null | head -n1); \
		if [ -n "$$LATEST_LEFT" ]; then \
			cp "$$LATEST_LEFT" /volumes/ADV360PRO/; \
			echo "Moved $$LATEST_LEFT to /volumes/ADV360PRO/"; \
		else \
			echo "No left firmware file found in firmware/ directory"; \
			exit 1; \
		fi; \
	else \
		echo "Error: /volumes/ADV360PRO directory not found"; \
		exit 1; \
	fi
