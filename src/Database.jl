# src/Database.jl
module Database

using LibPQ
using DataFrames
using Logging
using Genie # Access ENV vars easily

export DB_CONN_POOL, execute_query, fetch_df, fetch_row, init_db_connection

# Basic Connection Pool (Consider more robust pooling libraries for production)
const DB_CONN_POOL = Ref{Union{Nothing, LibPQ.Connection}}(nothing)
const MAX_RETRIES = 3

function db_connection_string()
    # Use Genie.config or ENV directly
    host = get(ENV, "DB_HOST", "localhost")
    port = get(ENV, "DB_PORT", "5432")
    dbname = get(ENV, "DB_DATABASE", "")
    user = get(ENV, "DB_USERNAME", "")
    password = get(ENV, "DB_PASSWORD", "")

    if isempty(dbname) || isempty(user)
        @error "Database configuration (DB_DATABASE, DB_USERNAME) missing in ENV or secrets.jl"
        # You might want to throw an error here or return an empty string to cause connection failure
        return ""
    end
    return "host=$host port=$port dbname=$dbname user=$user password=$password"
end

function init_db_connection()
    retries = 0
    conn_str = db_connection_string()
    if isempty(conn_str) return false end # Abort if config is missing

    while retries < MAX_RETRIES
        try
            DB_CONN_POOL[] = LibPQ.Connection(conn_str)
            # Check status after connection attempt
            if !isnothing(DB_CONN_POOL[]) && LibPQ.status(DB_CONN_POOL[]) == LibPQ.CONNECTION_OK
                 @info "Database connection established."
                 return true
            else
                 # Handle cases where Connection returns an object but status is bad
                 error_msg = isnothing(DB_CONN_POOL[]) ? "Connection object is null" : LibPQ.error_message(DB_CONN_POOL[])
                 @warn "DB connection attempt failed, status not OK: $error_msg"
                 # Close potentially bad connection object if it exists
                 !isnothing(DB_CONN_POOL[]) && close(DB_CONN_POOL[])
                 DB_CONN_POOL[] = nothing
            end
        catch ex
            @warn "Exception during DB connection (attempt $(retries+1)/$MAX_RETRIES): $ex"
            # Ensure pool is reset on exception too
             DB_CONN_POOL[] = nothing
        end

        retries += 1
        if retries < MAX_RETRIES
            sleep_time = 2.0^retries
            @info "Retrying DB connection in $sleep_time seconds..."
            sleep(sleep_time) # Exponential backoff
        else
            @error "Max DB connection retries reached. Check DB status and configuration."
            return false
        end
    end
     return false # Should not be reached if loop logic is correct, but ensures return
end

function get_connection()
    if isnothing(DB_CONN_POOL[]) || LibPQ.status(DB_CONN_POOL[]) != LibPQ.CONNECTION_OK
        @warn "DB connection lost or not initialized. Attempting to reconnect..."
        if !init_db_connection() # Attempt to reconnect
             error("Database connection is not available after reconnection attempt.")
        end
    end
    # Re-check after potential reconnection
    if isnothing(DB_CONN_POOL[]) || LibPQ.status(DB_CONN_POOL[]) != LibPQ.CONNECTION_OK
         error("Database connection is definitively not available.")
    end
    return DB_CONN_POOL[]
end

function execute_query(sql::String, params = []) :: LibPQ.Result
    try
        conn = get_connection()
        # Use LibPQ parameters properly
        return LibPQ.execute(conn, sql, params; throw_error=true)
    catch ex
        @error "Database query execution failed: SQL='$sql', PARAMS='$params', ERROR='$ex'"
        # Check for connection specific errors vs query errors
        if ex isa LibPQ.Errors.JLConnectionError || ex isa LibPQ.Errors.PQConnectionError
             @error "Connection Error Details: $(LibPQ.error_message(DB_CONN_POOL[]))"
             # Attempt to reset connection state?
             !isnothing(DB_CONN_POOL[]) && close(DB_CONN_POOL[])
             DB_CONN_POOL[] = nothing
        end
        rethrow()
    end
end

function fetch_df(sql::String, params = []) :: DataFrame
    result = execute_query(sql, params)
    df = DataFrame(result)
    # LibPQ.close(result) # Close resultset cursor explicitly
    return df
end

function fetch_row(sql::String, params = []) :: Union{DataFrameRow, Nothing}
    df = fetch_df(sql, params)
    if nrow(df) > 0
        return df[1, :]
    else
        return nothing
    end
end

end # module Database