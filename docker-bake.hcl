variable "VERSION" {}
variable "CREATED" {}
variable "REVISION" {}

function "tags" {
  params = [suffix]
  result = flatten([
    for host in ["", "ghcr.io/"] : [
      for version in ["", split(".", VERSION)[0], join(".", slice(split(".", VERSION), 0, 2)), VERSION] :
        ["${host}barnabyshearer/dockerfromscratch:${version}${version == "" ? "" : "-"}${suffix}"]
    ]
  ])
}

target "base" {
  context = "./"
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  labels = {
    "org.opencontainers.image.created" = CREATED
    "org.opencontainers.image.description" = "Builds docker images for a simple Python + Postgres App from scratch."
    "org.opencontainers.image.licenses" = "MIT"
    "org.opencontainers.image.revision" = REVISION
    "org.opencontainers.image.source" = "https://github.com/BarnabyShearer/DockerFromScratch"
    "org.opencontainers.image.title" = "dockerfromscratch"
    "org.opencontainers.image.url" = "https://github.com/BarnabyShearer/DockerFromScratch"
    "org.opencontainers.image.version" = VERSION
  }
}

group "default" {
  targets = ["python", "nginx", "postgres", "uwsgi"]
}

target "build" {
  inherits = ["base"]
  target = "build"
  tags = concat(tags("build"), ["barnabyshearer/dockerfromscratch:latest", "ghcr.io/barnabyshearer/dockerfromscratch:latest"])
}

target "python" {
  inherits = ["base"]
  target = "python"
  tags = tags("python")
}

target "nginx" {
  inherits = ["base"]
  target = "nginx"
  tags = tags("nginx")
}

target "postgres" {
  inherits = ["base"]
  target = "postgres"
  tags = tags("postgres")
}

target "uwsgi" {
  inherits = ["base"]
  target = "uwsgi"
  tags = tags("uwsgi")
}
