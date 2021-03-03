"""
    Run.script(path; <keyword arguments>)

Run Julia script at `path` after activating `\$path/Project.toml`.

See also [`Run.test`](@ref) and [`Run.docs`](@ref).

# Keyword Arguments
- `project::String`: Project to be used instead of `\$path/../Project.toml`.
- `parentproject::String`: Project to be added to `project` _if_ it does
  not have corresponding manifest file.
- `fast::Bool = false`: Try to run it faster (more precisely, skip
  `prepare` and pass `--compile=min` option to Julia subprocess.)
- `prepare::Bool = !fast`: Call `Run.prepare_test` if `true` (default).
- `compiled_modules::Union{Bool, Nothing} = nothing`:
  Use `--compiled-modules=yes` (`--compiled-modules=no`) option if
  `true` (`false`).  If `false`, it also skips precompilation in the
  preparation phase.
- `precompile::Bool = (compiled_modules != false)`: Precompile project
  before running script.
- `strict::Bool = true`: Do not include the default environment in the
  load path (more precisely, set the environment variable
  `JULIA_LOAD_PATH=@`).
- `code_coverage::Bool = false`: Control `--code-coverage` option.
- `check_bounds::Union{Nothing, Bool} = nothing`: Control
  `--check-bounds` option.  `nothing` means to inherit the option
  specified for the current Julia session.
- `depwarn::Union{Nothing, Bool, Symbol} = nothing`: Use `--depwarn` setting
  of the current process if `nothing` (default).  Set `--depwarn=yes` if `true`
  or `--depwarn=no` if `false`.  A symbol value is passed as `--depwarn` value.
  So, passing `:error` sets `--depwarn=error`.
- `xfail::bool = false`: If failure is expected.
- `exitcodes::AbstractVector{<:Integer}`: List of allowed exit codes.
  `xfail` is ignored when given.
- Other keywords are passed to `Run.prepare_test`.
"""
script

"""
    Run.test(path="test"; <keyword arguments>)

Run `\$path/runtests.jl` after activating `\$path/Project.toml`.  It
simply calls [`Run.script`](@ref) with default keyword arguments
`code_coverage = true`, `check_bounds = true`, and `depwarn = true`.

`path` can also be a path to a script file.

See also [`Run.script`](@ref) and [`Run`](#Run).
"""
test

"""
    Run.docs(path="docs"; <keyword arguments>)

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

project = something(Base.HOME_PROJECT[], Base.ACTIVE_PROJECT[], Some(nothing))
project === nothing && error("No project specified")

if !any(isfile.(joinpath.(project, ("JuliaManifest.toml", "Manifest.toml"))))
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
        println(io)
        println(io, "Command: ", Cmd(result.proc.cmd.exec))
        print(io, "Environment variables:")
        _printenv(io, something(result.proc.cmd.env, ENV))
    end
end

function _printenv(io, env)
    for nv in env
        if nv isa AbstractString
            name, value = split(nv, "=", limit = 2)
        else
            name, value = nv
        end
        # regex taken from `versioninfo`:
        if startswith(name, "JULIA") || occursin(r"PATH|FLAG|^TERM$|HOME", name)
            println(io)
            print(io, "  ", name, " = ", value)
        end
    end
end

struct Failed <: Exception
    result::Result
end

function Base.show(io::IO, ::MIME"text/plain", failed::Failed)
    print(io, "Failed ")
    show(io, MIME"text/plain"(), failed.result)
end

function Base.showerror(io::IO, failed::Failed)
    show(io, MIME"text/plain"(), failed)
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
    depwarn::Union{Bool, Symbol, Nothing} = nothing,
    kwargs...
)
    if julia_options !== nothing
        return julia_options, kwargs
    end

    jlopt = ``  # = julia_options
    addyn(cmd, ::Nothing) = jlopt
    addyn(cmd, yn::Bool) = `$jlopt $cmd=$(yesno(yn))`
    addopt(cmd, yn::Union{Bool, Nothing}) = addyn(cmd, yn)
    addopt(cmd, value::Symbol) = `$jlopt $cmd=$value`

    jlopt = addyn("--inline", inline)
    jlopt = addyn("--compiled-modules", compiled_modules)
    jlopt = addyn("--check-bounds", check_bounds)
    jlopt = code_coverage ? `$jlopt --code-coverage=user` : jlopt
    jlopt = addopt("--depwarn", depwarn)
    jlopt = fast ? `$jlopt --compile=min` : jlopt

    return jlopt, kwargs
end

function script(
    script;
    project=dirname(script),
    fast::Bool = false,
    prepare::Bool = !fast,
    strict::Bool = true,
    compiled_modules = nothing,
    precompile = (compiled_modules != false),
    parentproject = nothing,
    xfail::Bool = false,
    exitcodes::Union{Nothing,AbstractVector{<:Integer}} = nothing,
    kwargs...,
)
    if get(ENV, "CI", "false") == "true"
        InteractiveUtils.versioninfo()
        runtimeinfo()
        versioninfo()
    end
    script = checkexisting(script)
    projectpath = project
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
        proc = run(ignorestatus(cmd))
        result = Result("run finished", proc)
        if exitcodes === nothing
            if success(proc) == !xfail
                return result
            else
                throw(Failed(result))
            end
        else
            if proc.termsignal == 0 && proc.exitcode in exitcodes
                return result
            else
                throw(Failed(result))
            end
        end
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
    depwarn = true,
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
