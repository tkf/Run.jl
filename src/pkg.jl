const _PackageSpec = let pkg = PackageSpec("Package")
    T = typeof(pkg)
    getproperty(parentmodule(T), nameof(T))
end

function temporaryactivating(f, project)
    project === nothing && return f()
    current = Base.ACTIVE_PROJECT[]
    try
        Pkg.activate(project)
        return f()
    finally
        if current === nothing
            Pkg.activate()
        else
            Pkg.activate(current)
        end
    end
end

function test(spec::_PackageSpec; kwargs...)
    spec.name === nothing &&
        throw(ArgumentError("Package `name` must be specified in `spec`."))

    @info "Downloading $spec (i.e., installing it in a temporary environment...)"
    testpath = mktempdir() do project
        temporaryactivating(project) do
            Pkg.add(spec)
            pkgid = Base.identify_package(spec.name)
            return joinpath(dirname(dirname(Base.locate_package(pkgid))), "test")
        end
    end

    @info "Testing $spec..."
    return test(testpath; kwargs...)
end
