target "docker-metadata-action" {
  context = "./"
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
}

group "default" {
  targets = ["python", "nginx", "postgres", "uwsgi"]
}

target "build" {
  inherits = ["docker-metadata-action"]
  target = "build"
}

target "python" {
  inherits = ["docker-metadata-action"]
  target = "python"
}

target "nginx" {
  inherits = ["docker-metadata-action"]
  target = "nginx"
}

target "postgres" {
  inherits = ["docker-metadata-action"]
  target = "postgres"
}

target "uwsgi" {
  inherits = ["docker-metadata-action"]
  target = "uwsgi"
}
