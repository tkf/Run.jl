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

    pkgid = Base.PkgId(
        Base.UUID("22cec73e-a1b8-11e9-2c92-598750a2cf9c"),
        "InitialValues",
    )

    mktempdir() do project
        Run.temporaryactivating(project) do
            Pkg.add(pkgspec)
            Run.versioninfo(stdout, pkgid)
        end
    end
end
