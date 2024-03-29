using Run
using Run: Result, Failed
using Pkg
using Test

pass_script = joinpath(@__DIR__, "pass", "pass.jl")
fail_script = joinpath(@__DIR__, "fail", "fail.jl")
depwarn_no_script = joinpath(@__DIR__, "depwarn-no", "test.jl")
depwarn_yes_script = joinpath(@__DIR__, "depwarn-yes", "test.jl")
depwarn_error_script = joinpath(@__DIR__, "depwarn-error", "test.jl")
signal_script = joinpath(@__DIR__, "signal", "test.jl")
exit2_script = joinpath(@__DIR__, "exit2", "test.jl")

@testset "xfail" begin
    @testset "true pass" begin
        result = nothing
        @test begin
            result = Run.test(pass_script)
        end isa Result
        @test result.proc.exitcode == 0
        @test sprint(show, "text/plain", result) isa String
    end
    @testset "true failure" begin
        err = nothing
        @test try
            Run.test(fail_script)
            false
        catch err
            true
        end
        @test err.result.proc.exitcode == 1
        @test sprint(show, "text/plain", err) isa String
    end

    @testset "expected failure" begin
        result = nothing
        @test begin
            result = Run.test(fail_script; xfail = true)
        end isa Result
        @test result.proc.exitcode == 1
        @test sprint(show, "text/plain", result) isa String
        @test sprint(showerror, result) isa String
    end
    @testset "unexpected pass" begin
        err = nothing
        @test try
            Run.test(pass_script; xfail = true)
            false
        catch err
            true
        end
        @test err.result.proc.exitcode == 0
        @test sprint(show, "text/plain", err) isa String
        @test sprint(showerror, err) isa String
    end
end

@testset "depwarn" begin
    @test Run.test(depwarn_yes_script).proc.exitcode == 0
    @test Run.test(depwarn_yes_script; depwarn = false, xfail = true).proc.exitcode == 1
    @test Run.test(depwarn_no_script; depwarn = false).proc.exitcode == 0
    @test Run.test(depwarn_error_script; depwarn = :error).proc.exitcode == 0
end

@testset "signal" begin
    @test try
        Run.test(signal_script)
        nothing
    catch err
        err
    end isa Failed
    @test Run.test(signal_script, xfail = true) isa Result
end

@testset "exitcodes" begin
    @test Run.test(exit2_script, exitcodes = [2]) isa Result
    @test try
        Run.test(exit2_script; exitcodes = [0])
        nothing
    catch err
        err
    end isa Failed
    @test try
        Run.test(signal_script, exitcodes = [0])
        nothing
    catch err
        err
    end isa Failed
end

@testset "smoke test" begin
    withenv("DOCUMENTER_KEY" => nothing) do
        @test Run.docs(joinpath(@__DIR__, "..", "docs")) isa Any
    end

    pkgspec = PackageSpec(
        name = "InitialValues",
        rev = "4812f80c357a83021f71c7c3642f11eb1339aa56",
        # https://github.com/JuliaFolds/InitialValues.jl/commit/4812f80c357a83021f71c7c3642f11eb1339aa56
    )
    @test Run.test(pkgspec; project="test/environments/main") isa Any
    @test Run.test(pkgspec; project="test/environments/main", inline=false) isa Any

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
