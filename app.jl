module GenomicBreedingApp

using DotEnv, LibPQ, Tables
using GenieFramework
using DataFrames, StatsBase
using GenomicBreedingCore, GenomicBreedingIO

# Load configurations
DotEnv.load!(joinpath(homedir(), ".env"))

# Connect to database
function dbconnect()::LibPQ.Connection
    db_user = ENV["DB_USER"];
    db_password = ENV["DB_PASSWORD"];
    db_name = ENV["DB_NAME"];
    db_host = ENV["DB_HOST"];
    conn = LibPQ.Connection("dbname=$db_name user=$db_user password=$db_password host=$db_host")
    return conn
end

# Initialize the PostgreSQL database schema
function dbinit(schema_path::String = "db/schema.sql")::Nothing
    # schema_path = "db/schema.sql"
    conn = dbconnect()
    sql = read(schema_path, String)
    for stmt in split(sql, ';')
        stmt = strip(stmt)
        if !isempty(stmt)
            execute(conn, stmt)
        end
    end
    close(conn)
end

# Database interactions:
# 1. Upload new:
#   1.a. trials data
#   1.b. phenomes data
#   1.c. analysis information (including name and description)
#   1.d. TODO: reference genomes, and allele frequency data including genome coordinates
# 2. Update:
#   2.a. entries table with description
#   2.b. traits table with description
#   2.c. trials table with description
#   2.d. analyses table with additional analyses and/or tags on existing entry-trait-trial-layout combinations
#   2.e. TODO: genome marker variants table

function uploadtrialsorphenomes(; 
    fname::String,
    species::String = "unspecified",
    species_classification::Union{Missing, String} = missing,
    analysis::Union{Missing, String} = missing,
    analysis_description::Union{Missing, String} = missing,
    year::Union{Missing, Int64} = missing,
    season::Union{Missing, String} = missing, 
    harvest::Union{Missing, String} = missing, 
    site::Union{Missing, String} = missing, 
    sep::String = "\t",
    verbose::Bool = false
)::Nothing
    # genomes = GenomicBreedingCore.simulategenomes(n=10, verbose=false);
    # trials, _ = GenomicBreedingCore.simulatetrials(genomes=genomes, verbose=false);
    # trials.years = replace.(trials.years, "year_" => "202")
    # fname = writedelimited(trials)
    # # tebv = analyse(trials, "y ~ 1|entries"); phenomes = merge(merge(tebv.phenomes[1], tebv.phenomes[2]), tebv.phenomes[3]); fname = writedelimited(phenomes)
    # species = "unspecified"
    # species_classification = missing
    # analysis = missing
    # analysis_description = missing
    # year = missing
    # season = missing
    # harvest = missing
    # site = missing
    # sep = "\t"
    # verbose = true
    trials_or_phenomes = try
        try
            readdelimited(Trials, fname=fname, sep=sep, verbose=verbose)
        catch
            Suppressor.@suppress readjld2(Trials, fname=fname)
        end
    catch
        try 
            readdelimited(Phenomes, fname=fname, sep=sep, verbose=verbose)
        catch
            Suppressor.@suppress readjld2(Phenomes, fname=fname)
        end
    end
    df = tabularise(trials_or_phenomes)
    expression = """
        WITH
            entry AS (
                INSERT INTO entries (name, population, species, classification)
                VALUES (\$1, \$2, \$3, \$4)
                ON CONFLICT (name, population, species, classification) 
                DO UPDATE SET description = EXCLUDED.description
                RETURNING id
            ),
            trait AS (
                INSERT INTO traits (name)
                VALUES (\$5)
                ON CONFLICT (name) 
                DO UPDATE SET description = EXCLUDED.description
                RETURNING id
            ),
            trial AS (
                INSERT INTO trials (year, season, harvest, site)
                VALUES (\$6, \$7, \$8, \$9)
                ON CONFLICT (year, season, harvest, site)
                DO UPDATE SET description = EXCLUDED.description
                RETURNING id
            ),
            layout AS (
                INSERT INTO layouts (replication, block, row, col)
                VALUES (\$10, \$11, \$12, \$13)
                ON CONFLICT (replication, block, row, col)
                DO UPDATE SET replication = EXCLUDED.replication
                RETURNING id
            )
        INSERT INTO phenotype_data (entry_id, trait_id, trial_id, layout_id, value)
        SELECT entry.id, trait.id, trial.id, layout.id, \$14
        FROM entry, trait, trial, layout
        ON CONFLICT (entry_id, trait_id, trial_id, layout_id)
        DO NOTHING
    """
    expression_add_tag = if !ismissing(analysis)
        """
            WITH
                entry AS (
                    INSERT INTO entries (name, population, species, classification)
                    VALUES (\$1, \$2, \$3, \$4)
                    ON CONFLICT (name, population, species, classification) 
                    DO UPDATE SET description = EXCLUDED.description
                    RETURNING id
                ),
                trait AS (
                    INSERT INTO traits (name)
                    VALUES (\$5)
                    ON CONFLICT (name) 
                    DO UPDATE SET description = EXCLUDED.description
                    RETURNING id
                ),
                trial AS (
                    INSERT INTO trials (year, season, harvest, site)
                    VALUES (\$6, \$7, \$8, \$9)
                    ON CONFLICT (year, season, harvest, site)
                    DO UPDATE SET description = EXCLUDED.description
                    RETURNING id
                ),
                layout AS (
                    INSERT INTO layouts (replication, block, row, col)
                    VALUES (\$10, \$11, \$12, \$13)
                    ON CONFLICT (replication, block, row, col)
                    DO UPDATE SET replication = EXCLUDED.replication
                    RETURNING id
                ),
                analysis AS (
                    INSERT INTO analyses (name, description)
                    VALUES (\$14, \$15)
                    ON CONFLICT (name)
                    DO UPDATE SET name = EXCLUDED.name
                    RETURNING id
                )
            INSERT INTO analysis_tags (entry_id, trait_id, trial_id, layout_id, analysis_id)
            SELECT entry.id, trait.id, trial.id, layout.id, analysis.id
            FROM entry, trait, trial, layout, analysis
            ON CONFLICT (entry_id, trait_id, trial_id, layout_id, analysis_id)
            DO NOTHING
        """
    end
    conn = dbconnect()
    # execute(conn, "BEGIN;")
    traits = if isa(trials_or_phenomes, Trials)
        names(df)[12:end]
    else
        names(df)[4:end]
    end
    for trait in traits
        # trait = traits[1]
        for i in 1:nrow(df)
            # i = 1
            values = if isa(trials_or_phenomes, Trials)
                year_from_df = try
                    parse(Int64, df.years[i])
                catch
                    throw(ArgumentError("The year in line $i, i.e. `$(df.years[i])` cannot be parsed into Int64."))
                end    
                [
                    df.entries[i], df.populations[i], species, species_classification,
                    trait,
                    year_from_df, df.seasons[i], df.harvests[i], df.sites[i],
                    df.replications[i], df.blocks[i], df.rows[i], df.cols[i],
                    df[i, trait]
                ]
            else
                [
                    df.entries[i], df.populations[i], species, species_classification,
                    trait,
                    year, season, harvest, site,
                    missing, missing, missing, missing,
                    df[i, trait]
                ]
            end
            execute(conn, expression, values)
            if !ismissing(analysis)
                execute(conn, expression_add_tag, vcat(values[1:(end-1)], analysis, analysis_description))
            end
        end
    end
    # println("To commit please leave empty. To rollback enter any key:")
    # commit_else_rollback = readline()
    # if commit_else_rollback == ""
    #     execute(conn, "COMMIT;")
    # else
    #     execute(conn, "ROLLBACK;")
    # end
    close(conn)
end

# TODO TODO TODO TODO TODO TODO TODO TODO TODO
# TODO TODO TODO TODO TODO TODO TODO TODO TODO
# TODO: uploadgenomes, uploadcvs, etc...
# TODO TODO TODO TODO TODO TODO TODO TODO TODO
# TODO TODO TODO TODO TODO TODO TODO TODO TODO

function querytable(
    table::String;
    fields::Union{Missing, Vector{String}} = missing,
    filters::Union{Missing, Dict{String, Union{Tuple{Int64, Int64}, Vector{Int64}, Vector{String}}}} = missing,
)::DataFrame
    # Connect to the database
    conn = dbconnect()
    # Check arguments
    try execute(conn, raw"SELECT table_name FROM information_schema.tables WHERE table_name = \$1", [table])
    catch
        throw(ArgumentError("The table $table does not exist."))
    end
    for f in fields
        try execute(conn, raw"SELECT \$1 FROM information_schema.columns WHERE table_name = \$2", [f, table])
        catch
            throw(ArgumentError("The column $f does not exist in table $table."))
        end
    end
    for (k, _) in filters
        try execute(conn, raw"SELECT \$1 FROM information_schema.columns WHERE table_name = \$2", [string(k), table])
        catch
            throw(ArgumentError("The column $(string(k)) does not exist in table $table."))
        end
    end
    # Build the expression
    expression_vector = ["SELECT"]
    if ismissing(fields)
        push!(expression_vector, "* FROM")
    else
        push!(expression_vector, string(join(fields, ","), " FROM"))
    end
    if ismissing(filters)
        nothing
    else
        push!(expression_vector, "WHERE")
        conditions::Vector{String} = []
        for (k, v) in filters
            if isa(v, Tuple{Int64, Int64})
                push!(conditions, string("(", k, " BETWEEN ", v[1], " AND ", v[2]), ")")
            elseif isa(v, Vector{Int64})
                push!(conditions, string("(", k, " IN (", join(v, ","), ")"), ")")
            else
                # For Vector{String}
                # Notice the single-quotes between the string values
                push!(conditions, string("(", k, " IN ('", join(v, "','"), "')"), ")")
            end
        end
        push!(expression_vector, join(conditions, " AND "))
    end
    # Query
    res = execute(conn, join(expression_vector, " "))
    close(conn)
    # Output
    DataFrame(columntable(res))
end

function querytrialsandphenomes(;
    traits::Vector{String},
    species::Union{Missing, Vector{String}} = missing,
    classifications::Union{Missing, Vector{String}} = missing,
    populations::Union{Missing, Vector{String}} = missing,
    entries::Union{Missing, Vector{String}} = missing,
    years::Union{Missing, Vector{String}} = missing,
    seasons::Union{Missing, Vector{String}} = missing,
    harvests::Union{Missing, Vector{String}} = missing,
    sites::Union{Missing, Vector{String}} = missing,
    blocks::Union{Missing, Vector{String}} = missing,
    rows::Union{Missing, Vector{String}} = missing,
    cols::Union{Missing, Vector{String}} = missing,
    replications::Union{Missing, Vector{String}} = missing,
    include_all_fields::Bool = false,
    verbose::Bool = false,
)::Nothing
    # traits::Vector{String} = ["trait_1"];
    # species::Union{Missing, Vector{String}} = missing;
    # classifications::Union{Missing, Vector{String}} = missing;
    # populations::Union{Missing, Vector{String}} = missing;
    # entries::Union{Missing, Vector{String}} = missing;
    # years::Union{Missing, Vector{String}} = missing;
    # seasons::Union{Missing, Vector{String}} = missing;
    # harvests::Union{Missing, Vector{String}} = missing;
    # sites::Union{Missing, Vector{String}} = missing;
    # blocks::Union{Missing, Vector{String}} = missing;
    # rows::Union{Missing, Vector{String}} = missing;
    # cols::Union{Missing, Vector{String}} = missing;
    # replications::Union{Missing, Vector{String}} = missing;
    # include_all_fields::Bool = false;
    # verbose::Bool = false;
    expression_vector = 
    expression = """
        SELECT
            en.species,
            en.classification,
            en.population,
            en.name AS entry_name,
            tl.year,
            tl.season,
            tl.harvest,
            tl.site,
            tl.block,
            tl.row,
            tl.col,
            tl.replication,
            -- Use conditional aggregation to pivot traits into columns
            MAX(CASE WHEN tt.name = 'trait_1' THEN ys.value END) AS trait_1,
            MAX(CASE WHEN tt.name = 'trait_2' THEN ys.value END) AS trait_2,
            MAX(CASE WHEN tt.name = 'trait_3' THEN ys.value END) AS trait_3
        FROM
            phenotype_data ys
        JOIN
            entries en ON ys.entry_id = en.id
        JOIN
            traits tt ON ys.trait_id = tt.id
        JOIN
            trials tl ON ys.trial_id = tl.id
        WHERE
            -- Filters
            (
                en.name % 'entry'
                OR
                en.name = 'entry'
            )
            AND (
                en.population % 'pop'
                OR
                en.population = 'pop'
            )
            AND (
                en.species % 'unspecified'
                OR
                en.species = 'unspecified'
            )
            AND (
                en.classification % 'some_class'
                OR
                en.classification IS NULL
            )
            AND (
                tl.year IN (2022, 2023)
                OR
                tl.year BETWEEN 2022 AND 2025
            )
            AND (
                tl.season % (\$1)
                OR
                tl.season = (\$1)
            )
            AND (
                tl.harvest % 'harvest'
                OR
                tl.harvest IS NULL
            )
            AND (
                tl.site % 'site'
                OR
                tl.site IS NULL
            )
            AND (
                tl.block % 'block'
                OR
                tl.block IS NULL
            )
            AND (
                tl.row % 'row'
                OR
                tl.row IS NULL
            )
            AND (
                tl.col % 'col'
                OR
                tl.col IS NULL
            )
            AND (
                tl.replication % 'replication'
                OR
                tl.replication IS NULL
            )
        GROUP BY
            -- Group by all the non-aggregated columns that define a unique output row
            en.name,
            en.population,
            en.species,
            en.classification,
            tl.year,
            tl.season,
            tl.harvest,
            tl.site,
            tl.block,
            tl.row,
            tl.col,
            tl.replication
        ORDER BY -- Optional: Define how you want the results sorted
            en.name, tl.year, tl.site;
    """
    conn = dbconnect()
    res = execute(conn, expression, ["season_1"])
    out = columntable(res)
    if verbose
        @show string.(keys(out))
        @show Tables.matrix(out)
    end
    close(conn)
end

@genietools

@app begin
    @in tab_selected = "search_and_download"

    @in Text_text = ""
    @onchange Text_text begin
        println(Text_text)
    end

    @in trials_data = false
    @in genotype_data = false

    @out TableSearch_data = DataTable(
        DataFrame(
            name = [
                "Frozen Yogurt",
                "Ice cream sandwich",
                "Eclair",
                "Cupcake",
                "Gingerbread",
                "Jelly bean",
                "Lollipop",
                "Honeycomb",
                "Donut",
                "KitKat",
            ],
            calories = [159, 237, 262, 305, 356, 375, 392, 408, 452, 518],
            fat = [6.0, 9.0, 16.0, 3.7, 16.0, 0.0, 0.2, 3.2, 25.0, 26.0],
            carbs = [24, 37, 23, 67, 49, 94, 98, 87, 51, 65],
        ),
    )
    @in TableSearch_dfilter = ""


    @in N = 0
    @out m = 0.0
    @onchange N begin
        m = mean(rand(N))
    end
end

function uiheader()
    heading("GenomicBreedingApp", class = "bg-green-1")
end

function uisearchanddownload()
    [
        p("Search/Download Tab"),
        textfield(
            "Search",
            :Text_text,
            bottomslots = "",
            counter = "",
            maxlength = "12",
            dense = "",
            [
                template(
                    var"v-slot:append" = "",
                    [
                        icon(
                            "close",
                            @iif("Text_text !== ''"),
                            @click("Text_text = ''"),
                            class = "cursor-pointer",
                        ),
                    ],
                ),
            ],
        ),
        toggle(
            "Raw Trials Data", 
            :trials_data, 
            color = "green", 
        ),
        toggle(
            "Genotype Data", 
            :genotype_data, 
            color = "blue", 
        ),
        p("\t"),
        btn(
            "Query",
            @click(:ButtonProgress_process),
            loading = :ButtonProgress_process,
            percentage = :ButtonProgress_progress,
            color = "green",
        ),
        spinner(:hourglass, color = "green", size = "3em"),
        separator(color = "primary"),
        table(
            :TableSearch_data,
            flat = true,
            bordered = true,
            title = "Treats",
            var"row-key" = "name",
            filter = :TableSearch_dfilter,
            hideheader = "",
            template(
                var"v-slot:top-right" = "",
                textfield(
                    "",
                    :TableSearch_dfilter,
                    dense = true,
                    debounce = "300",
                    placeholder = "Search",
                    [template(var"v-slot:append" = true, icon("search"))],
                ),
            ),
        )
    ]
end

function ui()
    [
        uiheader(),

        tabgroup(
            :tab_selected,
            align = "justify",
            inlinelabel = true,
            class = "bg-primary text-white shadow-2",
            [
                tab(name = "search_and_download", icon = "search", label = "Search/Download"),
                tab(name = "analyse_and_plot", icon = "analytics", label = "Analyse/Plot"),
                tab(name = "upload_and_validate", icon = "upload", label = "Upload/Validate"),
            ],
        ),
        tabpanels(
            :tab_selected,
            animated = true,
            var"transition-prev" = "scale",
            var"transition-next" = "scale",
            [
                tabpanel(name = "search_and_download", uisearchanddownload()),
                tabpanel(name = "analyse_and_plot", [p("Analyse/Plot Tab")]),
                tabpanel(name = "upload_and_validate", [p("Upload/Validate Tab")]),
            ],
        ),

        cell([
            textfield("How many numbers?", :N),
            p("The average of {{N}} random numbers is {{m}}"),
            
        ]),
    ]
end

@page("/", ui)
end
