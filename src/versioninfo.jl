versioninfo() = versioninfo(stdout)
versioninfo(io) = versioninfo(io, Base.PkgId(@__MODULE__))

function versioninfo(io, pkg)
    entry = find_pkg_entry(pkg, Base.load_path())
    entry === nothing && error("No package information ($pkg not installed?).")

    print(io, pkg)
    if haskey(entry, "version")
        print(io, " version ", entry["version"])
    end
    println(io)

    keys = [
        "git-tree-sha1",
        "repo-url",
        "repo-rev",
    ]
    padn = maximum(length.(keys)) + 1
    for key in keys
        if haskey(entry, key)
            print(io, rpad(key, padn), ": ")
            printstyled(io, entry[key], color=:blue)
            println(io)
        end
    end
end

isomething(xs) =
    for x in xs
        x === nothing || return x
    end

tryfind(f, xs) = isomething(f(x) ? x : nothing for x in xs)

find_pkg_entry(pkg, paths) = isomething(find_pkg_entry.(Ref(pkg), paths))

function find_pkg_entry(pkg, path::AbstractString)
    isfile(path) || return
    manifest = tryfind(
        isfile,
        joinpath.(dirname(path), ["JuliaManifest.toml", "Manifest.toml"]),
    )
    dict = TOML.parsefile(manifest)
    pkgs = something(
        get(dict, pkg.name, nothing),
        get(get(dict, "deps", Dict()), pkg.name, nothing),  # v2
        [],
    )
    return tryfind(pkgs) do entry
        Base.UUID(get(entry, "uuid", 0)) === pkg.uuid
    end
end
