module Run

@doc read(joinpath(dirname(@__DIR__), "README.md"), String) Run

if VERSION ≥ v"1.6-"
    try
        using Coverage
    catch
        @info "Failed to import Coverage. Trying again with `@stdlib`..."
        push!(LOAD_PATH, "@stdlib")
    end
end

using Pkg
using Pkg: TOML
using UUIDs: UUID
import Coverage
import InteractiveUtils
import LinearAlgebra

include("core.jl")
include("versioninfo.jl")
include("runtimeinfo.jl")
include("pkg.jl")
include("migratetest.jl")

end # module
