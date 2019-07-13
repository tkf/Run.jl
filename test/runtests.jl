using Run
using Pkg
using Test

@testset "smoke test" begin
    @test Run.docs(joinpath(@__DIR__, "..", "docs")) isa Any

    pkgspec = PackageSpec(
        name = "InitialValues",
        url = "https://github.com/tkf/InitialValues.jl",
        rev = "62b240fb85836b9731b0a893e446a9c90311afce",
    )
    @test Run.test(pkgspec) isa Any
    @test Run.test(pkgspec; inline=false) isa Any
end
