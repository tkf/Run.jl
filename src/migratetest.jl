"""
    Run.migratetest(path=".")

Migrate test setup from `[targets]` in `\$path/Project.toml` to
`\$path/test/Project.toml`.
"""
migratetest

function migratetest(path="."; include_deps=false)
    prj = TOML.parsefile(projecttomlpath(path))

    if include_deps
        deps = copy(prj["deps"])
    else
        deps = Dict{String,String}()
    end
    for name in get(get(prj, "targets", Dict()), "test", [])
        deps[name] = prj["extras"][name]
    end
    specs = [PackageSpec(name=name, uuid=UUID(uuid)) for (name, uuid) in deps]
    parentproject = Pkg.PackageSpec(path=abspath(path))

    temporaryactivating(abspath(joinpath(path, "test"))) do
        Pkg.develop(parentproject)
        Pkg.add(specs)
    end
end

function temporaryactivating(f, project)
    try
        Pkg.activate(project)
        return f()
    finally
        Pkg.activate()
    end
end
