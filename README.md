# GenomicBreedingApp

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://GenomicBreeding.github.io/GenomicBreedingApp.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://GenomicBreeding.github.io/GenomicBreedingApp.jl/dev)
[![Build Status](https://github.com/GenomicBreeding/GenomicBreedingApp.jl/workflows/CI/badge.svg)](https://github.com/GenomicBreeding/GenomicBreedingApp.jl/actions)

## Install the dependencies

```shell
julia --project -e 'using Pkg; Pkg.instantiate()'
```
## Open the app in julia

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



<details>
<summary>Details</summary>

## Example PostgreSQL setup

### 1. Install PostgreSQL via conda and start the server

```shell
# conda install anaconda::postgresql
# pg_ctl -D $CONDA_PREFIX/pgsql_data start
sudo apt install postgresql postgresql-common postgresql-contrib
sudo systemctl start postgresql.service
# sudo nano /etc/postgresql/*/main/postgresql.conf # --> set: `listen_addresses = '*'` and `port = 5432`
sudo systemctl restart postgresql.service
sudo -u postgres psql
# # MISC
# # sudo systemctl start postgresql
# # sudo systemctl enable postgresql
# # sudo ufw allow 5432/tcp
# # sudo -u postgres psql
# # sudo systemctl start postgresql.service
# # sudo systemctl restart postgresql.service
# # sudo -i -u postgres
# # initdb -D ${HOME}/db
# # pg_ctl -D ${HOME}/db -l logfile start &
# # pg_ctl -D ${HOME}/db status
```

### 2. Instantiate the database

Open the PostgreSQL shell:

```shell
sudo -u postgres psql
```

Create a new database:

```sql
CREATE DATABASE gbdb;
\l
\c gbdb
\dt
CREATE USER jeff WITH PASSWORD 'qwerty12345';
GRANT ALL PRIVILEGES ON SCHEMA public TO jeff;
GRANT ALL PRIVILEGES ON DATABASE gbdb TO jeff;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO other_user;
\q
```

### 3. Define the login credentials

```shell
# Save as ~/.env
DB_USER="jeff"
DB_PASSWORD="qwerty12345"
DB_NAME="gbdb"
DB_HOST="localhost"
ls -lhtr $CONDA_PREFIX/pgsql_data/
cat $CONDA_PREFIX/pgsql_data/pg_hba.conf

```

### 4. Add extensions

```shell
sudo apt install postgresql-contrib
```

</details>