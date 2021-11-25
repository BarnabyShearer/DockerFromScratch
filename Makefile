VERSION=10.1.0
CREATED=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
REVISION=$(git rev-parse HEAD)
export VERSION CREATED REVISION

lint:
	docker run --rm --interactive --volume "${PWD}"/.hadolint.yaml:/.hadolint.yaml hadolint/hadolint < Dockerfile

bake:
	docker buildx bake build
	docker buildx bake
