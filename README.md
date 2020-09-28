# Run

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://tkf.github.io/Run.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tkf.github.io/Run.jl/dev)
[![Build Status](https://travis-ci.com/tkf/Run.jl.svg?branch=master)](https://travis-ci.com/tkf/Run.jl)
[![Codecov](https://codecov.io/gh/tkf/Run.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tkf/Run.jl)
[![Coveralls](https://coveralls.io/repos/github/tkf/Run.jl/badge.svg?branch=master)](https://coveralls.io/github/tkf/Run.jl?branch=master)
[![GitHub last commit](https://img.shields.io/github/last-commit/tkf/Run.jl.svg?style=social&logo=github)](https://github.com/tkf/Run.jl)

Run.jl provides functions to run tests or build documentation in an
isolated environment.  See more in the
[documentation](https://tkf.github.io/Run.jl/dev).

## Features

* Simpler CI setup (`.travis.yml`, `.gitlab-ci.yml`, etc.)
* Isolated and activatable sub-environments for Julia < 1.2.
* Reproducible runs not only for test but also for any sub-projects
  (docs, benchmarks, etc.)
* Finer Julia options (e.g., `Run.test(fast=true)` to run tests faster
  by minimizing JIT compilation.)

## Examples

### `.github/workflow/*.yml`

Here is an example for using Run.jl with GitHub Actions.  Create a
file, e.g., `.github/workflow/test.yml`, with:

```yaml
name: Run tests

on:
  push:
    branches:
      - master
    tags: '*'
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        julia-version: ['1']
      fail-fast: false
    name: Test Julia ${{ matrix.julia-version }}
    steps:
      - uses: actions/checkout@v2
      - name: Setup julia
        uses: julia-actions/setup-julia@v1
        with:
          version: ${{ matrix.julia-version }}
      - run: julia -e 'using Pkg; pkg"add Run@0.1"'
      - run: julia -e 'using Run; Run.prepar()'
      - run: julia -e 'using Run; Run.test()'
      - uses: julia-actions/julia-processcoverage@v1
      - uses: codecov/codecov-action@v1
        with:
          file: ./lcov.info
          flags: unittests
          name: codecov-umbrella
```

### `.travis.yml`

To use `Run.test` to run tests in Travis CI, add the following snippet
in `.travis.yml`.

```yaml
before_install:
  - unset JULIA_PROJECT
  - julia -e 'using Pkg; pkg"add Run@0.1"'
install:
  - julia -e 'using Run; Run.prepare_test()'
script:
  - julia -e 'using Run; Run.test()'
after_success:
  - julia -e 'using Run; Run.after_success_test()'
jobs:
  include:
    - stage: Documentation
      install:
        - julia -e 'using Run; Run.prepare_docs()'
      script:
        - julia -e 'using Run; Run.docs()'
      after_success: skip
```

Side notes:

* `Run.prepare_test()` and `Run.prepare_docs()` are not required but
  it is a good idea to separate installation and test.
* The test log can be minimized by passing `prepare=false` to `Run.test`.

### `.gitlab-ci.yml`

```yaml
.template:
  image: julia
  before_script:
    - julia -e 'using Pkg; pkg"add Run@0.1"'

test:
  extends: .template
  script:
    - julia -e 'using Run; Run.test()'

pages:
  extends: .template
  stage: deploy
  script:
    - julia -e 'using Run; Run.docs()'
    - mv docs/build public
  artifacts:
    paths:
      - public
  only:
    - master
```
