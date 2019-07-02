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

## Examples

To use `Run.test` to run tests in Travis CI, add the following snippet
in `.travis.yml`.

```yaml
install:
  - unset JULIA_PROJECT
  - julia -e 'using Pkg; pkg"add https://github.com/tkf/Run.jl"'
  - julia -e 'using Run; Run.prepare_test()'
script:
  - julia -e 'using Run; Run.test()'
after_success:
  - julia -e 'using Run; Run.after_success_test()'
```

Side notes:

* `Run.prepare_test()` is not required but it is a good idea to
  separate installation and test.
* The test log can be minimized by passing `prepare=false` to `Run.test`.
* Use `Run.prepare_docs()` and `Run.docs()` for building documentation.
