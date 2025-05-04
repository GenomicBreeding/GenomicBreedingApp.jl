# GenomicBreedingApp

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://GenomicBreeding.github.io/GenomicBreedingApp.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://GenomicBreeding.github.io/GenomicBreedingApp.jl/dev)
[![Build Status](https://github.com/GenomicBreeding/GenomicBreedingApp.jl/workflows/CI/badge.svg)](https://github.com/GenomicBreeding/GenomicBreedingApp.jl/actions)

## Install the dependencies

```shell
julia --project -e 'using Pkg; Pkg.instantiate()'
```

## Install, instantiate, and start the PostgrSQL database

See the (GenomicBreedingDB.jl)[https://github.com/GenomicBreeding/GenomicBreedingDB.jl] repository for installation and initialisation instructions.

To start the database:
```shell
conda activate GenomicBreeding
pg_ctl -D $CONDA_PREFIX/pgsql_data -l $CONDA_PREFIX/pgsql_data/logfile.txt start
```

## Open the app in julia

```shell
julia --project --load test/deploy.jl
```

Or manually via:

```shell
julia --project
```

```julia
using GenieFramework
Genie.loadapp()
up(8001, async = true)
```

## Usage

Open your browser and navigate to http://localhost:8001/
