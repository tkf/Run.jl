"""
    Run.script(path; <keyword arguments>)

Run Julia script at `path` after activating `\$path/Project.toml`.

See also [`Run.test`](@ref) and [`Run.docs`](@ref).

# Keyword Arguments
- `fast::Bool = false`: Try to run it faster (more precisely, skip
  `prepare` and pass `--compile=min` option to Julia subprocess.)
- `prepare::Bool = !fast`: Call `Run.prepare_test` if `true` (default).
- `compiled_modules::Union{Bool, Nothing} = nothing`:
  Use `--compiled-modules=yes` (`--compiled-modules=no`) option if
  `true` (`false`).  If `false`, it also skips precompilation in the
  preparation phase.
- `strict::Bool = true`: Do not include the default environment in the
  load path (more precisely, set the environment variable
  `JULIA_LOAD_PATH=@`).
- `code_coverage::Bool = false`: Control `--code-coverage` option.
- `check_bounds::Union{Nothing, Bool} = nothing`: Control
  `--check-bounds` option.  `nothing` means to inherit the option
  specified for the current Julia session.
- Other keywords are passed to `Run.prepare_test`.
"""
script

"""
    Run.test(path="test"; prepare, fast, compiled_modules, strict, precompile)

Run `\$path/runtests.jl` after activating `\$path/Project.toml`.  It
simply calls [`Run.script`](@ref) with default keyword arguments
`code_coverage = true` and `check_bounds = true`.

`path` can also be a path to a script file.

See also [`Run.script`](@ref) and [`Run`](#Run).
"""
test

"""
    Run.docs(path="docs"; prepare, fast, compiled_modules, strict, precompile)

Run `\$path/make.jl` after activating `\$path/Project.toml`.  It
simply calls [`Run.script`](@ref).

`path` can also be a path to a script file.
"""
docs

"""
    Run.prepare(path::AbstractString; precompile, parentproject)

Instantiate `\$path/Project.toml`.  It also `dev`s the project in the parent
directory of `path` into `\$path/Project.toml` if `\$path/Manifest.toml`
does not exist.

# Keyword Arguments
- `precompile::Bool = true`: Precompile the project if `true` (default).
- `parentproject::AbstractString`: Path to parent project.  Default to
  parent directory of `path`.
"""
prepare

"""
    Run.prepare_test(path="test"; precompile)

It is an alias of [`Run.prepare("test")`](@ref Run.prepare).
"""
prepare_test

"""
    Run.prepare_docs(path="docs"; precompile)

It is an alias of [`Run.prepare("docs")`](@ref Run.prepare).
"""
prepare_docs

existingfile(path) = isfile(path) ? path : nothing

_tomlpath(dir, candidates) =
    something(existingfile.(joinpath.(dir, candidates))...,
              joinpath(dir, candidates[2]))

projecttomlpath(dir) = _tomlpath(dir, ("JuliaProject.toml", "Project.toml"))
manifesttomlpath(dir) = _tomlpath(dir, ("JuliaManifest.toml", "Manifest.toml"))

function checkexisting(path)
    isfile(path) && return path
    error("File `$path` does not exist.")
end

existingproject(name) = checkexisting(projecttomlpath(name))

const prepare_code = """
parentproject, = ARGS

Pkg = Base.require(Base.PkgId(Base.UUID(0x44cfe95a1eb252eab672e2afdf69b78f), "Pkg"))

Base.HOME_PROJECT[] === nothing && error("No project specified")

if !any(isfile.(joinpath.(Base.HOME_PROJECT[], ("JuliaManifest.toml", "Manifest.toml"))))
    @info "Manifest.toml is missing.  Adding `\$parentproject` in dev mode."
    Pkg.develop(Pkg.PackageSpec(path=parentproject))
end

@info "Instantiating..."
@time Pkg.instantiate()
@info "Instantiating... DONE"
"""

const precompile_code = """
@info "Precompiling..."
@time Pkg.API.precompile()
@info "Precompiling... DONE"
"""

yesno(yes::Bool) = yes ? "yes" : "no"

_julia_cmd() = `$(Base.julia_cmd()) --color=yes --startup-file=no`
# TODO: use --color=yes only when make sense

struct Result
    message::String
    proc
end

function Base.show(io::IO, ::MIME"text/plain", result::Result)
    print(io, "Result: ", result.message)
    exitcode = result.proc.exitcode
    if exitcode !== 0
        print(io, " ")
        printstyled(io, "(exit code: ", exitcode, ")"; color=:red)
    end
end

function prepare(projectpath; precompile=true, parentproject=nothing)
    projectpath = dirname(existingproject(projectpath))
    code = prepare_code
    if precompile
        code = string(code, "\n", precompile_code)
    end
    if parentproject === nothing
        parentproject = dirname(abspath(projectpath))
    end
    env = copy(ENV)
    env["JULIA_PROJECT"] = projectpath
    cmd = setenv(`$(_julia_cmd()) -e $code -- $parentproject`, env)
    return Result("preparation finished", run(cmd))
end

function _default_julia_options(;
    julia_options::Union{Cmd, Nothing} = nothing,
    fast::Bool = false,
    inline::Union{Bool, Nothing} = nothing,
    compiled_modules::Union{Bool, Nothing} = nothing,
    code_coverage::Bool = false,
    check_bounds::Union{Bool, Nothing} = nothing,
    kwargs...
)
    if julia_options !== nothing
        return julia_options, kwargs
    end

    jlopt = ``  # = julia_options
    addyn(cmd, ::Nothing) = jlopt
    addyn(cmd, yn::Bool) = `$jlopt $cmd=$(yesno(yn))`

    jlopt = addyn("--inline", inline)
    jlopt = addyn("--compiled-modules", compiled_modules)
    jlopt = addyn("--check-bounds", check_bounds)
    jlopt = code_coverage ? `$jlopt --code-coverage=user` : jlopt
    jlopt = fast ? `$jlopt --compile=min` : jlopt

    return jlopt, kwargs
end

function script(
    script;
    fast::Bool = false,
    prepare::Bool = !fast,
    strict::Bool = true,
    compiled_modules = nothing,
    precompile = (compiled_modules != false),
    parentproject = nothing,
    kwargs...,
)
    if get(ENV, "CI", "false") == "true"
        versioninfo()
    end
    script = checkexisting(script)
    projectpath = dirname(script)
    julia_options, kwargs = _default_julia_options(;
        fast = fast,
        compiled_modules = compiled_modules,
        kwargs...
    )
    projecttoml = existingproject(projectpath)
    manifesttoml = manifesttomlpath(projectpath)
    projectpath = abspath(dirname(projecttoml))
    if parentproject === nothing
        parentproject = dirname(projectpath)
    end
    mktempdir() do tmpproject
        cp(projecttoml, joinpath(tmpproject, "Project.toml"))
        if isfile(manifesttoml)
            copymanifest(manifesttoml, joinpath(tmpproject, "Manifest.toml"))
        end
        prepare && (@__MODULE__).prepare(
            tmpproject;
            precompile = precompile,
            parentproject = parentproject,
            kwargs...,
        )
        env = copy(ENV)
        env["JULIA_PROJECT"] = tmpproject
        if strict
            env["JULIA_LOAD_PATH"] = "@"
        end
        @info "Running $script"
        cmd = setenv(`$(_julia_cmd()) $julia_options $script`, env)
        return Result("run finished", run(cmd))
    end
end
# Note: Copying toml files to make it work nicely with running script
# which may mutate the toml files.  For example,
# `PkgBenchmark.benchmarkpkg` can check out new revision containing
# different toml files.

prepare_test(path="test"; kwargs...) = prepare(path; kwargs...)
prepare_docs(path="docs"; kwargs...) = prepare(path; kwargs...)

function existingscript(path, candidates)
    candidates = abspath.(candidates)
    i = findfirst(isfile, candidates)
    i === nothing || return candidates[i]
    error(
        "No script file found at `$path`.\n",
        "Following paths are checked, but none of the paths exist:\n",
        join(string.("*", candidates), "\n"),
    )
end

test(path="test"; kwargs...) = script(
    existingscript(path, (path, joinpath(path, "runtests.jl")));
    code_coverage = true,
    check_bounds = true,
    kwargs...
)
docs(path="docs"; kwargs...) = script(
    existingscript(path, (path, joinpath(path, "make.jl")));
    kwargs...
)


function after_success_test()
    Coverage.Codecov.submit(Coverage.process_folder())
    Coverage.Coveralls.submit(Coverage.process_folder())
end
