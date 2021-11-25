lint:
	docker run --rm --interactive --volume "${PWD}"/.hadolint.yaml:/.hadolint.yaml hadolint/hadolint < Dockerfile
