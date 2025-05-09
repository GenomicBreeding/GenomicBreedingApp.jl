using GenieFramework
Genie.loadapp()
up(8001, async = true)

using StatsBase, DataFrames, Tables, CSV, StippleDownloads
using PlotlyBase
using GenieFramework
using GenomicBreedingCore, GenomicBreedingIO
# Make sure the PostgreSQL database is running (see https://github.com/GenomicBreeding/GenomicBreedingDB.jl)
using GenomicBreedingDB, DotEnv
# Load database credentials
DotEnv.load!(joinpath(homedir(), ".env"))
