BAZEL_FILES = $(shell find . -type f \( -iname '*.bazel' -or -iname '*.bzl' \))
PROTO_FOLDERS := $(filter-out ./external%, $(shell find ./proto -name '*.proto' -print0 | xargs -0 -n1 dirname | sort --unique))

.PHONY: deps
deps:
	go mod tidy
	go mod vendor

.PHONY: local-deps
local-deps:
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.46.2; \
	go install github.com/bazelbuild/buildtools/buildifier@5.1.0;

.PHONY: gazelle-update-repos
gazelle-update-repos:
	bazelisk run //:gazelle-update-repos

.PHONY: gazelle
gazelle:
	bazelisk run //:gazelle

.PHONY: gazelle-check
gazelle-check:
	bazelisk run //:gazelle -- -mode diff

.PHONY: lint
lint:
	golangci-lint run ./cmd/... ./pkg/...

.PHONY: buildifier-check
buildifier-check:
	buildifier --mode=check --lint=warn \
		--warnings=-function-docstring,-function-docstring-header,-function-docstring-args,-function-docstring-return,-module-docstring,-skylark-docstring,-rule-impl-return \
		$(BAZEL_FILES)

.PHONY: buildifier
buildifier:
	buildifier --lint=fix \
		--warnings=-function-docstring,-function-docstring-header,-function-docstring-args,-function-docstring-return,-module-docstring,-skylark-docstring,-rule-impl-return \
		$(BAZEL_FILES)

.PHONY: build
build:
	bazelisk build //cmd/... //proto/...

.PHONY: run-server
run-server:
	bazelisk run //cmd/server:server

.PHONY: run-client
run-client:
	bazelisk run //cmd/client:client

.PHONY: proto
proto: remove-go
	for f in ${PROTO_FOLDERS}; do \
		protoc \
			-I=./proto \
			--go_out=plugins=grpc:./proto \
			--go_opt=paths=source_relative \
			$$f/*.proto; \
	done

.PHONY: proto-fmt
proto-fmt:
	find . -name "*.proto" | grep -v external | xargs clang-format -i

.PHONY: proto-fmt-check
proto-fmt-check:
	test -z "$$(find . -name "*.proto" | grep -v external | xargs clang-format -i -output-replacements-xml | grep "<replacement ")"

.PHONY: remove-go
remove-go:
	find ./proto -name "*.pb.go" -type f -delete

.PHONY: clean
clean:
	rm -rf bazel-*
	rm -rf vendor
	bazelisk clean --expunge

# Docker

.PHONY: build-docker-images
build-docker-images:
	bazelisk build //cmd/server:image

.PHONY: push-docker-images
push-docker-images:
	cat ~/ghcr.txt | docker login ghcr.io -u $(GITHUB_TOKEN_USER) --password-stdin
	bazelisk run //cmd/server:image_push_github
