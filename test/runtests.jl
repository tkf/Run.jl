using Run
using Pkg
using Test

@testset "smoke test" begin
    @test Run.docs(joinpath(@__DIR__, "..", "docs")) isa Any
    @test Run.test(PackageSpec(
        name = "UniversalIdentity",
        url = "https://github.com/tkf/UniversalIdentity.jl",
    )) isa Any
    @test Run.test(PackageSpec(
        name = "UniversalIdentity",
        url = "https://github.com/tkf/UniversalIdentity.jl",
    ); inline=false) isa Any
end
