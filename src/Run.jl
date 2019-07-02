module Run

@doc read(joinpath(dirname(@__DIR__), "README.md"), String) Run

using Pkg
using Pkg: TOML
using UUIDs: UUID
import Coverage

include("core.jl")
include("pkg.jl")
include("migratetest.jl")

end # module
