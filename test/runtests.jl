using Run
using Run: Result, Failed
using Pkg
using Test

pass_script = joinpath(@__DIR__, "pass", "pass.jl")
fail_script = joinpath(@__DIR__, "fail", "fail.jl")

@testset "xfail" begin
    @testset "true pass" begin
        result = nothing
        @test begin
            result = Run.test(pass_script)
        end isa Result
        @test result.proc.exitcode == 0
    end
    @testset "true failure" begin
        @test_throws Failed Run.test(fail_script)
    end

    @testset "expected failure" begin
        result = nothing
        @test begin
            result = Run.test(fail_script; xfail = true)
        end isa Result
        @test result.proc.exitcode == 1
    end
    @testset "unexpected pass" begin
        @test_throws Failed Run.test(pass_script; xfail = true)
    end
end

@testset "smoke test" begin
    withenv("DOCUMENTER_KEY" => nothing) do
        @test Run.docs(joinpath(@__DIR__, "..", "docs")) isa Any
    end

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
