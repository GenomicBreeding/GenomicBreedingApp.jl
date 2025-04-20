module GenomicBreedingApp

using DotEnv, LibPQ, Tables
using GenieFramework
using DataFrames, StatsBase
using GenomicBreedingCore, GenomicBreedingIO

# Load configurations
DotEnv.load!(joinpath(homedir(), ".env"))

# Connect to database
function dbconnect()
    db_user = ENV["DB_USER"];
    db_password = ENV["DB_PASSWORD"];
    db_name = ENV["DB_NAME"];
    db_host = ENV["DB_HOST"];
    conn = LibPQ.Connection("dbname=$db_name user=$db_user password=$db_password host=$db_host")
    return conn
end

# Initialize the PostgreSQL database schema
function dbinit(schema_path::String = "db/schema.sql")
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

function uploadtrials(; 
    fname::String,
    species::String = "unspecified",
    classification::Union{Missing, String} = missing,
    description::Union{Missing, String} = missing,
    analysis_name::Union{Missing, String} = missing,
    analysis_description::Union{Missing, String} = missing,
    sep::String = "\t",
    verbose::Bool = false
)::Nothing
    # genomes = GenomicBreedingCore.simulategenomes(n=10, verbose=false);
    # trials, _ = GenomicBreedingCore.simulatetrials(genomes=genomes, verbose=false);
    # trials.years = replace.(trials.years, "year_" => "202")
    # fname = writedelimited(trials); sep = "\t"; verbose = true;
    # species = "unspecified"
    # classification = missing
    # description = missing
    # analysis_name = missing
    trials = try
        readdelimited(Trials, fname=fname, sep=sep, verbose=verbose)
    catch
        readjld2(Trials, fname=fname)
    end
    df = tabularise(trials)
    expression = """
        WITH
            entry AS (
                INSERT INTO entries (name, population, species, classification, description)
                VALUES (\$1, \$2, \$3, \$4, \$5)
                ON CONFLICT (name, species) 
                DO UPDATE SET name = EXCLUDED.name
                RETURNING id
            ),
            trait AS (
                INSERT INTO traits (name, description) 
                VALUES (\$6, \$7)
                ON CONFLICT (name) 
                DO UPDATE SET name = EXCLUDED.name
                RETURNING id
            ),
            trial AS (
                INSERT INTO trials (year, season, harvest, site, treatment, description)
                VALUES (\$8, \$9, \$10, \$11, \$12, \$13)
                ON CONFLICT (year, season, harvest, site, treatment)
                DO UPDATE SET year = EXCLUDED.year
                RETURNING id
            ),
            layout AS (
                INSERT INTO layouts (replication, block, row, col)
                VALUES (\$14, \$15, \$16, \$17)
                ON CONFLICT (replication, block, row, col)
                DO UPDATE SET replication = EXCLUDED.replication
                RETURNING id
            )
        INSERT INTO phenotype_data (entry_id, trait_id, trial_id, layout_id, value)
        SELECT entry.id, trait.id, trial.id, layout.id, \$18
        FROM entry, trait, trial, layout
        ON CONFLICT (entry_id, trait_id, trial_id, layout_id)
        DO NOTHING
    """
    # expression_add_tag = if !ismissing(analysis_name)
    #     """
    #         WITH 
    #             entry AS (
    #                 INSERT INTO entries (name, population, species, classification, description)
    #                 VALUES (\$1, \$2, \$3, \$4, \$5)
    #                 ON CONFLICT (name, species) 
    #                 DO UPDATE SET name = EXCLUDED.name
    #                 RETURNING id
    #             ),
    #             trial AS (
    #                 INSERT INTO trials (year, season, harvest, site, block, row, col, replication)
    #                 VALUES (\$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13)
    #                 ON CONFLICT (year, season, harvest, site, block, row, col, replication)
    #                 DO UPDATE SET year = EXCLUDED.year
    #                 RETURNING id
    #             ),
    #             trait AS (
    #                 INSERT INTO traits (name) 
    #                 VALUES (\$14)
    #                 ON CONFLICT (name) 
    #                 DO UPDATE SET name = EXCLUDED.name
    #                 RETURNING id
    #             ),
    #             analysis AS (
    #                 INSERT INTO traits (name) 
    #                 VALUES (\$14)
    #                 ON CONFLICT (name) 
    #                 DO UPDATE SET name = EXCLUDED.name
    #                 RETURNING id
    #             )
    #         INSERT INTO analysis_tags (analysis_id, entry_id, trial_id, trait_id)
    #         SELECT \$15, entry.id, trial.id, trait.id
    #         FROM entry, trial, trait
    #         ON CONFLICT (analysis_id, entry_id, trial_id, trait_id)
    #         DO NOTHING
    #     """
    # end
    conn = dbconnect()
    execute(conn, "BEGIN;")
    traits = names(df)[12:end]
    for trait in traits
        # trait = traits[1]
        for i in 1:nrow(df)
            # i = 1
            year = try
                parse(Int64, df.years[i])
            catch
                throw(ArgumentError("The year in line $i, i.e. `$(df.years[i])` cannot be parsed into Int64."))
            end
            input = [
                df.entries[i], df.populations[i], species, classification, description,
                year, df.seasons[i], df.harvests[i], df.sites[i], df.blocks[i], df.rows[i], df.cols[i], df.replications[i],
                trait, df[i, trait],
            ]
            res = execute(conn, expression, input)
            if !ismissing(analysis_name)
                execute(conn, expression_add_tag, vcat(input[1:(end-1)], analysis_name))
            end
        end
    end
    println("To commit please leave empty. To rollback enter any key:")
    commit_else_rollback = readline()
    if commit_else_rollback == ""
        execute(conn, "COMMIT;")
    else
        execute(conn, "ROLLBACK;")
    end
    close(conn)
end

function uploadphenomes(; 
    fname::String,
    species::String = "unspecified",
    classification::Union{Missing, String} = missing,
    description::Union{Missing, String} = missing,
    year::Union{Missing, Int64} = missing,
    season::Union{Missing, String} = missing, 
    harvest::Union{Missing, String} = missing, 
    site::Union{Missing, String} = missing, 
    analysis_tag::Union{Missing, String} = missing,
    sep::String = "\t", 
    verbose::Bool = false
)::Nothing
    # genomes = GenomicBreedingCore.simulategenomes(n=10, verbose=false);
    # trials, _ = GenomicBreedingCore.simulatetrials(genomes=genomes, verbose=false);
    # trials.years = replace.(trials.years, "year_" => "202")
    # tebv = analyse(trials, "y ~ 1|entries")
    # phenomes = merge(merge(tebv.phenomes[1], tebv.phenomes[2]), tebv.phenomes[3])
    # fname = writedelimited(phenomes); sep = "\t"; verbose = true;
    # species = "unspecified"
    # classification = missing
    # description = missing
    # year = missing; season = missing; harvest = missing; site = missing;
    phenomes = try
        readdelimited(Phenomes, fname=fname, sep=sep, verbose=verbose)
    catch
        readjld2(Phenomes, fname=fname)
    end
    df = tabularise(phenomes)
    expression = """
        WITH 
            entry AS (
                INSERT INTO entries (name, population, species, classification, description) 
                VALUES (\$1, \$2, \$3, \$4, \$5)
                ON CONFLICT (name, species) 
                DO UPDATE SET name = EXCLUDED.name
                RETURNING id
            ),
            trial AS (
                INSERT INTO trials (year, season, harvest, site) -- excludes: block, row, col, replication
                VALUES (\$6, \$7, \$8, \$9)
                ON CONFLICT (year, season, harvest, site, block, row, col, replication)
                DO UPDATE SET year = EXCLUDED.year
                RETURNING id
            ),
            trait AS (
                INSERT INTO traits (name) 
                VALUES (\$10)
                ON CONFLICT (name) 
                DO UPDATE SET name = EXCLUDED.name
                RETURNING id
            )
        INSERT INTO phenotype_data (entry_id, trial_id, trait_id, value)
        SELECT entry.id, trial.id, trait.id, \$11
        FROM entry, trial, trait
        ON CONFLICT (entry_id, trial_id, trait_id)
        DO NOTHING
    """
    conn = dbconnect()
    traits = names(df)[4:end]
    for trait in traits
        # trait = traits[1]
        for i in 1:nrow(df)
            # i = 1
            input = [
                df.entries[i], df.populations[i], species, classification, description,
                year, season, harvest, site,
                trait, df[i, trait],
            ]
            res = execute(conn, expression, input)
        end
    end
    close(conn)
end

# TODO TODO TODO TODO TODO TODO TODO TODO TODO
# TODO TODO TODO TODO TODO TODO TODO TODO TODO
# TODO: uploadgenomes, uploadcvs, etc...
# TODO TODO TODO TODO TODO TODO TODO TODO TODO
# TODO TODO TODO TODO TODO TODO TODO TODO TODO

function querytrialsandphenomes(;
    traits::Vector{Union{Missing, String}},
    species::Vector{Union{Missing, String}} = [missing],
    classifications::Vector{Union{Missing, String}} = [missing],
    populations::Vector{Union{Missing, String}} = [missing],
    entries::Vector{Union{Missing, String}} = [missing],
    years::Vector{Union{Missing, String}} = [missing],
    seasons::Vector{Union{Missing, String}} = [missing],
    harvests::Vector{Union{Missing, String}} = [missing],
    sites::Vector{Union{Missing, String}} = [missing],
    blocks::Vector{Union{Missing, String}} = [missing],
    rows::Vector{Union{Missing, String}} = [missing],
    cols::Vector{Union{Missing, String}} = [missing],
    replications::Vector{Union{Missing, String}} = [missing],
    include_all_fields::Bool = false,
    verbose::Bool = false,
)::Nothing
    # traits::Vector{Union{Missing, String}};
    # species::Vector{Union{Missing, String}} = [missing];
    # classifications::Vector{Union{Missing, String}} = [missing];
    # populations::Vector{Union{Missing, String}} = [missing];
    # entries::Vector{Union{Missing, String}} = [missing];
    # years::Vector{Union{Missing, String}} = [missing];
    # seasons::Vector{Union{Missing, String}} = [missing];
    # harvests::Vector{Union{Missing, String}} = [missing];
    # sites::Vector{Union{Missing, String}} = [missing];
    # blocks::Vector{Union{Missing, String}} = [missing];
    # rows::Vector{Union{Missing, String}} = [missing];
    # cols::Vector{Union{Missing, String}} = [missing];
    # replications::Vector{Union{Missing, String}} = [missing];
    # include_all_fields::Bool = false;
    # verbose::Bool = false;
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
