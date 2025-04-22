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
# psql postgres
wget https://ftp.postgresql.org/pub/source/v17.4/postgresql-17.4.tar.gz
wget https://ftp.postgresql.org/pub/source/v17.4/postgresql-17.4.tar.gz.sha256
x=$(cat postgresql-17.4.tar.gz.sha256 | cut -f1 -d' ')
y=$(sha256sum postgresql-17.4.tar.gz | cut -f1 -d' ')
if [ $x = $y ]
then
    echo "OK"
fi
tar -xzvf postgresql-17.4.tar.gz
rm postgresql-17.4.tar.gz
cd postgresql-17.4/
# Create a new conda environment, install dependencies and build PostgreSQL from source
conda create -n postgresql
conda activate postgresql
conda install -c conda-forge make icu bison flex openssl perl-lib
./configure --without-icu --with-openssl --prefix=$CONDA_PREFIX # OpenSSL is required by pgcrypto
make world-bin
make install-world-bin
# Initialise the database cluster
initdb -D $CONDA_PREFIX/pgsql_data
# Start the server
pg_ctl -D $CONDA_PREFIX/pgsql_data restart
psql postgres
# # On Debian-based systems
# sudo apt install postgresql postgresql-common postgresql-contrib
# sudo systemctl start postgresql.service
# # sudo nano /etc/postgresql/*/main/postgresql.conf # --> set: `listen_addresses = '*'` and `port = 5432`
# sudo systemctl restart postgresql.service
# sudo -u postgres psql
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
psql postgres
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
# ls -lhtr $CONDA_PREFIX/pgsql_data/
# cat $CONDA_PREFIX/pgsql_data/pg_hba.conf
```

### 4. Add extensions

```shell
sudo apt install postgresql-contrib
```

</details>