module Run

"""
    Run.test(path="test"; prepare, fast, strict, precompile)

Run `\$path/runtests.jl` after activating `\$path/Project.toml`.

# Keyword Arguments
- `prepare::Bool = true`: Call `Run.prepare_test` if `true` (default).
- `fast::Bool = false`: Try to run it faster (more precisely, pass
  `--compile=min` option to Julia subprocess.)
- `strict::Bool = true`: Do not include the default environment in the
  load path (more precisely, set the environment variable
  `JULIA_LOAD_PATH=@`).
- Other keywords are passed to `Run.prepare_test`.
"""
test

"""
    Run.docs(path="docs"; prepare, fast, strict, precompile)

See [`Run.test`](@ref).
"""
docs

"""
    Run.prepare_test(path="test"; precompile)

Instantiate `\$path/Project.toml`.  It also `dev`s the project in the parent
directory of `path` into `\$path/Project.toml` if `\$path/Manifest.toml`
does not exist.

# Keyword Arguments
- `precompile::Bool = true`: Precompile
"""
prepare_test

"""
    Run.prepare_docs(path="docs"; precompile)

See [`Run.prepare_test`](@ref).
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

using Pkg

Base.HOME_PROJECT[] === nothing && error("No project specified")

if !any(isfile.(joinpath.(Base.HOME_PROJECT[], ("JuliaManifest.toml", "Manifest.toml"))))
    @info "Manifest.toml is missing.  Adding `\$parentproject` in dev mode."
    Pkg.develop(PackageSpec(path=parentproject))
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

_julia_cmd() = `$(Base.julia_cmd()) --color=yes --startup-file=no`
# TODO: use --color=yes only when make sense

function prepare(projectpath; precompile=true, parentproject=nothing)
    projectpath = dirname(existingproject(projectpath))
    code = prepare_code
    if precompile
        code = string(code, "\n", precompile_code)
    end
    if parentproject === nothing
        parentproject = dirname(abspath(projectpath))
    end
    cmd = setenv(
        `$(_julia_cmd()) -e $code -- $parentproject`,
        "JULIA_PROJECT" => projectpath,
    )
    run(cmd)
end

function runproject(
    script;
    prepare::Bool = true,
    fast::Bool = false,
    strict::Bool = true,
    julia_options::Cmd = ``,
    kwargs...,
)
    script = checkexisting(script)
    projectpath = dirname(script)
    prepare && (@__MODULE__).prepare(projectpath; kwargs...)
    if fast
        julia_options = `--compile=min $julia_options`
    end
    envs = [
        "JULIA_PROJECT" => projectpath,
    ]
    if strict
        push!(envs, "JULIA_LOAD_PATH" => "@")
    end
    @info "Running $script"
    cmd = setenv(`$(_julia_cmd()) $julia_options $script`, envs...)
    run(cmd)
end

prepare_test(path="test"; kwargs...) = prepare(path; kwargs...)
prepare_docs(path="docs"; kwargs...) = prepare(path; kwargs...)

test(path="test"; kwargs...) = runproject(
    joinpath(path, "runtests.jl");
    julia_options = `--code-coverage=user --check-bounds=yes`,
    kwargs...,
)
docs(path="docs"; kwargs...) = runproject(joinpath(path, "make.jl"); kwargs...)

end # module
