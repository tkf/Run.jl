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

function copymanifest(oldpath::AbstractString, newpath::AbstractString)
    open(newpath; write=true) do io
        for line in eachline(oldpath; keep=true)
            m = match(r"(path *= *)\"(.*?)\"", line)
            if m !== nothing && !isabspath(m.captures[2])
                write(io, m.captures[1])
                write(io, repr(joinpath(dirname(abspath(oldpath)), m.captures[2])))
                println(io)
            else
                write(io, line)
            end
        end
    end
end
