workflow "build and release" {
  on = "push"
  resolves = ["release"]
}

action "build docker image" {
  uses = "actions/docker/cli@master"
  args = "build -t tartiflette-aiohttp ."
}

action "build artifact" {
  uses = "./github-actions/python/"
  runs = "make"
  args = "build-artifact"
}

action "unit test" {
  needs = ["build docker image"]
  uses = "actions/docker/cli@master"
  args = "run -i tartiflette-aiohttp make test-unit"
}

# action "functional test" {
#   needs = ["build docker image"]
#   uses = "actions/docker/cli@master"
#   args = "run -i tartiflette-aiohttp make test-functional"
# }

# action "integration test" {
#   needs = ["build docker image"]
#   uses = "actions/docker/cli@master"
#   args = "run -i tartiflette-aiohttp make test-integration"
# }

# action "style" {
#   needs = ["build docker image"]
#   uses = "actions/docker/cli@master"
#   args = "run -i tartiflette-aiohttp make style"
# }

# action "complexity" {
#   needs = ["build docker image"]
#   uses = "actions/docker/cli@master"
#   args = "run -i tartiflette-aiohttp make complexity"
# }

action "set version and changelog" {
  uses = "./github-actions/shell/"
  # needs = ["unit test", "functional test", "integration test", "style", "complexity", "build artifact"]
  needs = ["unit test", "build artifact"]
  runs = "make"
  args = "github-action-version-and-changelog"
}

action "is master" {
  uses = "actions/bin/filter@master"
  needs = ["set version and changelog"]
  args = "branch master"
}

action "is ref master" {
  uses = "./github-actions/shell/"
  needs = ["is master"]
  runs = "is_ref"
  env = {
    REF_NAME = "refs/heads/master"
  }
}

action "publish to pypi" {
  uses = "./github-actions/pypi/"
  secrets = ["TWINE_PASSWORD", "TWINE_USERNAME"]
  needs = ["is ref master"]
}

action "release" {
  uses = "./github-actions/release/"
  secrets = ["GITHUB_TOKEN"]
  needs = ["publish to pypi"]
  env = {
    USERNAME = "dailymotion"
    REPOSITORY = "tartiflette-aiohttp"
  }
}
