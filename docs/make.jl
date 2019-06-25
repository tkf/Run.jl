using Documenter, Run

makedocs(;
    modules=[Run],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/tkf/Run.jl/blob/{commit}{path}#L{line}",
    sitename="Run.jl",
    authors="Takafumi Arakaki <aka.tkf@gmail.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/tkf/Run.jl",
)
