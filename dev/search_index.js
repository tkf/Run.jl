var documenterSearchIndex = {"docs":
[{"location":"#Run.jl","page":"Home","title":"Run.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Run\nRun.script\nRun.test\nRun.docs\nRun.prepare\nRun.prepare_test\nRun.prepare_docs\nRun.migratetest","category":"page"},{"location":"#Run","page":"Home","title":"Run","text":"Run\n\n(Image: Stable) (Image: Dev) (Image: Build Status) (Image: Codecov) (Image: Coveralls) (Image: GitHub last commit)\n\nRun.jl provides functions to run tests or build documentation in an isolated environment.  See more in the documentation.\n\nFeatures\n\nSimpler CI setup (.travis.yml, .gitlab-ci.yml, etc.)\nIsolated and activatable sub-environments for Julia < 1.2.\nReproducible runs not only for test but also for any sub-projects (docs, benchmarks, etc.)\nFiner Julia options (e.g., Run.test(fast=true) to run tests faster by minimizing JIT compilation.)\n\nExamples\n\n.github/workflow/*.yml\n\nHere is an example for using Run.jl with GitHub Actions.  Create a file, e.g., .github/workflow/test.yml, with:\n\nname: Run tests\n\non:\n  push:\n    branches:\n      - master\n    tags: '*'\n  pull_request:\n\njobs:\n  test:\n    runs-on: ubuntu-latest\n    strategy:\n      matrix:\n        julia-version: ['1']\n      fail-fast: false\n    name: Test Julia ${{ matrix.julia-version }}\n    steps:\n      - uses: actions/checkout@v2\n      - name: Setup julia\n        uses: julia-actions/setup-julia@v1\n        with:\n          version: ${{ matrix.julia-version }}\n      - run: julia -e 'using Pkg; pkg\"add Run@0.1\"'\n      - run: julia -e 'using Run; Run.prepare_test()'\n      - run: julia -e 'using Run; Run.test()'\n      - uses: julia-actions/julia-processcoverage@v1\n      - uses: codecov/codecov-action@v1\n        with:\n          file: ./lcov.info\n          flags: unittests\n          name: codecov-umbrella\n\n.travis.yml\n\nTo use Run.test to run tests in Travis CI, add the following snippet in .travis.yml.\n\nbefore_install:\n  - unset JULIA_PROJECT\n  - julia -e 'using Pkg; pkg\"add Run@0.1\"'\ninstall:\n  - julia -e 'using Run; Run.prepare_test()'\nscript:\n  - julia -e 'using Run; Run.test()'\nafter_success:\n  - julia -e 'using Run; Run.after_success_test()'\njobs:\n  include:\n    - stage: Documentation\n      install:\n        - julia -e 'using Run; Run.prepare_docs()'\n      script:\n        - julia -e 'using Run; Run.docs()'\n      after_success: skip\n\nSide notes:\n\nRun.prepare_test() and Run.prepare_docs() are not required but it is a good idea to separate installation and test.\nThe test log can be minimized by passing prepare=false to Run.test.\n\n.gitlab-ci.yml\n\n.template:\n  image: julia\n  before_script:\n    - julia -e 'using Pkg; pkg\"add Run@0.1\"'\n\ntest:\n  extends: .template\n  script:\n    - julia -e 'using Run; Run.test()'\n\npages:\n  extends: .template\n  stage: deploy\n  script:\n    - julia -e 'using Run; Run.docs()'\n    - mv docs/build public\n  artifacts:\n    paths:\n      - public\n  only:\n    - master\n\n\n\n\n\n","category":"module"},{"location":"#Run.script","page":"Home","title":"Run.script","text":"Run.script(path; <keyword arguments>)\n\nRun Julia script at path after activating $path/Project.toml.\n\nSee also Run.test and Run.docs.\n\nKeyword Arguments\n\nproject::String: Project to be used instead of $path/../Project.toml.\nparentproject::String: Project to be added to project if it does not have corresponding manifest file.\nfast::Bool = false: Try to run it faster (more precisely, skip prepare and pass --compile=min option to Julia subprocess.)\nprepare::Bool = !fast: Call Run.prepare_test if true (default).\ncompiled_modules::Union{Bool, Nothing} = nothing: Use --compiled-modules=yes (--compiled-modules=no) option if true (false).  If false, it also skips precompilation in the preparation phase.\nprecompile::Bool = (compiled_modules != false): Precompile project before running script.\nstrict::Bool = true: Do not include the default environment in the load path (more precisely, set the environment variable JULIA_LOAD_PATH=@).\ncode_coverage::Bool = false: Control --code-coverage option.\ncheck_bounds::Union{Nothing, Bool} = nothing: Control --check-bounds option.  nothing means to inherit the option specified for the current Julia session.\ndepwarn::Union{Nothing, Bool, Symbol} = nothing: Use --depwarn setting of the current process if nothing (default).  Set --depwarn=yes if true or --depwarn=no if false.  A symbol value is passed as --depwarn value. So, passing :error sets --depwarn=error.\nxfail::bool = false: If failure is expected.\nexitcodes::AbstractVector{<:Integer}: List of allowed exit codes. xfail is ignored when given.\nOther keywords are passed to Run.prepare_test.\n\n\n\n\n\n","category":"function"},{"location":"#Run.test","page":"Home","title":"Run.test","text":"Run.test(path=\"test\"; <keyword arguments>)\n\nRun $path/runtests.jl after activating $path/Project.toml.  It simply calls Run.script with default keyword arguments code_coverage = true, check_bounds = true, and depwarn = true.\n\npath can also be a path to a script file.\n\nSee also Run.script and Run.\n\n\n\n\n\n","category":"function"},{"location":"#Run.docs","page":"Home","title":"Run.docs","text":"Run.docs(path=\"docs\"; <keyword arguments>)\n\nRun $path/make.jl after activating $path/Project.toml.  It simply calls Run.script.\n\npath can also be a path to a script file.\n\n\n\n\n\n","category":"function"},{"location":"#Run.prepare","page":"Home","title":"Run.prepare","text":"Run.prepare(path::AbstractString; precompile, parentproject)\n\nInstantiate $path/Project.toml.  It also devs the project in the parent directory of path into $path/Project.toml if $path/Manifest.toml does not exist.\n\nKeyword Arguments\n\nprecompile::Bool = true: Precompile the project if true (default).\nparentproject::AbstractString: Path to parent project.  Default to parent directory of path.\n\n\n\n\n\n","category":"function"},{"location":"#Run.prepare_test","page":"Home","title":"Run.prepare_test","text":"Run.prepare_test(path=\"test\"; precompile)\n\nIt is an alias of Run.prepare(\"test\").\n\n\n\n\n\n","category":"function"},{"location":"#Run.prepare_docs","page":"Home","title":"Run.prepare_docs","text":"Run.prepare_docs(path=\"docs\"; precompile)\n\nIt is an alias of Run.prepare(\"docs\").\n\n\n\n\n\n","category":"function"},{"location":"#Run.migratetest","page":"Home","title":"Run.migratetest","text":"Run.migratetest(path=\".\")\n\nMigrate test setup from [targets] in $path/Project.toml to $path/test/Project.toml.\n\n\n\n\n\n","category":"function"}]
}
