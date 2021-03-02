try
    @show unsafe_pointer_to_objref(Ptr{Nothing}(0))
catch
end

for s in [Base.SIGTERM, Base.SIGINT, Base.SIGHUP, Base.SIGINT, Base.SIGKILL]
    try
        ccall(:kill, Cvoid, (Cint,Cint), getpid(), s)
        sleep(1)
    catch
    end
end
