var documenterSearchIndex = {"docs":
[{"location":"#Run.jl-1","page":"Home","title":"Run.jl","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Run\nRun.test\nRun.docs\nRun.prepare_test\nRun.prepare_docs\nRun.migratetest","category":"page"},{"location":"#Run","page":"Home","title":"Run","text":"Run\n\n(Image: Stable) (Image: Dev) (Image: Build Status) (Image: Codecov) (Image: Coveralls) (Image: GitHub last commit)\n\nRun.jl provides functions to run tests or build documentation in an isolated environment.  See more in the documentation.\n\nExamples\n\nTo use Run.test to run tests in Travis CI, add the following snippet in .travis.yml.\n\ninstall:\n  - unset JULIA_PROJECT\n  - julia -e 'using Pkg; pkg\"add https://github.com/tkf/Run.jl\"'\n  - julia -e 'using Run; Run.prepare_test()'\nscript:\n  - julia -e 'using Run; Run.test()'\nafter_success:\n  - julia -e 'using Run; Run.after_success_test()'\n\nSide notes:\n\nRun.prepare_test() is not required but it is a good idea to separate installation and test.\nThe test log can be minimized by passing prepare=false to Run.test.\nUse Run.prepare_docs() and Run.docs() for building documentation.\n\n\n\n\n\n","category":"module"},{"location":"#Run.test","page":"Home","title":"Run.test","text":"Run.test(path=\"test\"; prepare, fast, compiled_modules, strict, precompile)\n\nRun $path/runtests.jl after activating $path/Project.toml.\n\nSee also Run.\n\nKeyword Arguments\n\nprepare::Bool = true: Call Run.prepare_test if true (default).\nfast::Bool = false: Try to run it faster (more precisely, pass --compile=min option to Julia subprocess.)\ncompiled_modules::Union{Bool, Nothing} = nothing: Use --compiled-modules=yes (--compiled-modules=no) option if true (false).  If false, it also skips precompilation in the preparation phase.\nstrict::Bool = true: Do not include the default environment in the load path (more precisely, set the environment variable JULIA_LOAD_PATH=@).\nOther keywords are passed to Run.prepare_test.\n\n\n\n\n\n","category":"function"},{"location":"#Run.docs","page":"Home","title":"Run.docs","text":"Run.docs(path=\"docs\"; prepare, fast, compiled_modules, strict, precompile)\n\nSee Run.test.\n\n\n\n\n\n","category":"function"},{"location":"#Run.prepare_test","page":"Home","title":"Run.prepare_test","text":"Run.prepare_test(path=\"test\"; precompile)\n\nInstantiate $path/Project.toml.  It also devs the project in the parent directory of path into $path/Project.toml if $path/Manifest.toml does not exist.\n\nKeyword Arguments\n\nprecompile::Bool = true: Precompile the project if true (default).\n\n\n\n\n\n","category":"function"},{"location":"#Run.prepare_docs","page":"Home","title":"Run.prepare_docs","text":"Run.prepare_docs(path=\"docs\"; precompile)\n\nSee Run.prepare_test.\n\n\n\n\n\n","category":"function"},{"location":"#Run.migratetest","page":"Home","title":"Run.migratetest","text":"Run.migratetest(path=\".\")\n\nMigrate test setup from [targets] in $path/Project.toml to $path/test/Project.toml.\n\n\n\n\n\n","category":"function"}]
}
