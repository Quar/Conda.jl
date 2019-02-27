using Compat

const condadir = abspath(first(DEPOT_PATH), "conda")
const condadeps = joinpath(condadir, "deps.jl")

module DefaultDeps
    using Compat
    if isfile("deps.jl")
        include("deps.jl")
    elseif isfile(Main.condadeps)
        include(Main.condadeps)
    end
    if !isdefined(@__MODULE__, :MINICONDA_VERSION)
        const MINICONDA_VERSION = "3"
    end
    if !isdefined(@__MODULE__, :ROOTENV)
        const ROOTENV = joinpath(Main.condadir, MINICONDA_VERSION)
    end
end

ROOTENV = get(ENV, "CONDA_JL_HOME", DefaultDeps.ROOTENV)
MINICONDA_VERSION = get(ENV, "CONDA_JL_VERSION", DefaultDeps.MINICONDA_VERSION)
CONDA_JL_CONDA_EXE = if haskey(ENV, "CONDA_JL_HOME")
    get(ENV, "CONDA_JL_CONDA_EXE", get(ENV, "CONDA_EXE", nothing))
else
    nothing
end

if isdir(ROOTENV) && MINICONDA_VERSION != DefaultDeps.MINICONDA_VERSION
    error("""Miniconda version changed, since last build.
However, a root enviroment already exists at $(ROOTENV).
Setting Miniconda version is not supported for existing root enviroments.
To leave Miniconda version as, it is unset the CONDA_JL_VERSION enviroment variable and rebuild.
To change Miniconda version, you must delete the root enviroment and rebuild.
WARNING: deleting the root enviroment will delete all the packages in it.
This will break many Julia packages that have used Conda to install their dependancies.
These will require rebuilding.
""")
end

deps = """
const ROOTENV = "$(escape_string(ROOTENV))"
const MINICONDA_VERSION = "$(escape_string(MINICONDA_VERSION))"
const CONDA_JL_CONDA_EXE = "$(escape_string(CONDA_JL_CONDA_EXE))"
"""

mkpath(condadir)
mkpath(ROOTENV)

for depsfile in ("deps.jl", condadeps)
    if !isfile(depsfile) || read(depsfile, String) != deps
        write(depsfile, deps)
    end
end
