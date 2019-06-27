module Run

@doc read(joinpath(dirname(@__DIR__), "README.md"), String) Run

using Pkg
using Pkg: TOML
using UUIDs: UUID

include("core.jl")
include("migratetest.jl")

end # module
