using Run
using Test

@testset "smoke test" begin
    @test Run.docs(joinpath(@__DIR__, "..", "docs")) isa Any
end
