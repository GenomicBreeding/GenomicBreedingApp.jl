module GenomicBreedingApp

using DotEnv, LibPQ
using GenieFramework
using DataFrames, StatsBase
using GenomicBreedingCore, GenomicBreedingIO
@genietools

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

function uploadtrials(; fname::String, sep::String = "\t", verbose::Bool = false)
    # genomes = GenomicBreedingCore.simulategenomes(n=10, verbose=false);
    # trials, _ = GenomicBreedingCore.simulatetrials(genomes=genomes, verbose=false);
    # trials.years = replace.(trials.years, "year_" => "202")
    # fname = writedelimited(trials); sep = "\t"; verbose = true;
    trials = try
        readdelimited(Trials, fname=fname, sep=sep, verbose=verbose)
    catch
        readjld2(Trials, fname=fname)
    end
    df = tabularise(trials)
    expression = """
        WITH 
            entry AS (
                INSERT INTO entries (name, population) 
                VALUES (\$1, \$2)
                ON CONFLICT (name) 
                DO UPDATE SET name = EXCLUDED.name
                RETURNING id
            ),
            trial AS (
                INSERT INTO trials (year, season, harvest, site, block, row, col, replication)
                VALUES (\$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10)
                ON CONFLICT (year, season, harvest, site, block, row, col, replication)
                DO UPDATE SET year = EXCLUDED.year
                RETURNING id
            ),
            trait AS (
                INSERT INTO traits (name) 
                VALUES (\$11)
                ON CONFLICT (name) 
                DO UPDATE SET name = EXCLUDED.name
                RETURNING id
            )
        INSERT INTO phenotype_data (entry_id, trial_id, trait_id, value)
        SELECT entry.id, trial.id, trait.id, \$12
        FROM entry, trial, trait
        ON CONFLICT (entry_id, trial_id, trait_id)
        DO NOTHING
    """
    conn = dbconnect()
    traits = names(df)[12:end]
    for trait in traits
        # trait = traits[1]
        for i in 1:nrow(df)
            # i = 1
            input = [
                df.entries[i], df.populations[i], 
                parse(Int64, df.years[i]), df.seasons[i], df.harvests[i], df.sites[i], df.blocks[i], df.rows[i], df.cols[i], df.replications[i],
                trait, df[i, trait],
            ]
            res = execute(conn, expression, input)
        end
    end
    close(conn)
end

function uploadphenomes(; 
    fname::String,
    year::Union{Missing, Int64} = missing,
    season::Union{Missing, String} = missing, 
    harvest::Union{Missing, String} = missing, 
    site::Union{Missing, String} = missing, 
    sep::String = "\t", verbose::Bool = false)
    # genomes = GenomicBreedingCore.simulategenomes(n=10, verbose=false);
    # trials, _ = GenomicBreedingCore.simulatetrials(genomes=genomes, verbose=false);
    # trials.years = replace.(trials.years, "year_" => "202")
    # tebv = analyse(trials, "y ~ 1|entries")
    # phenomes = merge(merge(tebv.phenomes[1], tebv.phenomes[2]), tebv.phenomes[3])
    # fname = writedelimited(phenomes); sep = "\t"; verbose = true;
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
                INSERT INTO entries (name, population) 
                VALUES (\$1, \$2)
                ON CONFLICT (name) 
                DO UPDATE SET name = EXCLUDED.name
                RETURNING id
            ),
            trial AS (
                INSERT INTO trials (year, season, harvest, site) -- excludes: block, row, col, replication
                VALUES (\$3, \$4, \$5, \$6)
                ON CONFLICT (year, season, harvest, site, block, row, col, replication)
                DO UPDATE SET year = EXCLUDED.year
                RETURNING id
            ),
            trait AS (
                INSERT INTO traits (name) 
                VALUES (\$7)
                ON CONFLICT (name) 
                DO UPDATE SET name = EXCLUDED.name
                RETURNING id
            )
        INSERT INTO phenotype_data (entry_id, trial_id, trait_id, value)
        SELECT entry.id, trial.id, trait.id, \$8
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
                df.entries[i], df.populations[i], 
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

function querytrialsandphenomes()
    expression = """
        SELECT
            pd.value,          -- The phenotype measurement
            t.name AS trait_name, -- Name of the trait
            e.name AS entry_name,  -- Name of the genetic entry
            e.population,      -- Population of the entry
            tr.year,           -- Trial year
            tr.season,         -- Trial season
            tr.harvest,        -- Trial harvest
            tr.site,           -- Trial site
            tr.block,          -- Other trial details you might want
            tr.row,
            tr.col,
            tr.replication
        FROM
            phenotype_data pd
        JOIN
            entries e ON pd.entry_id = e.id
        JOIN
            traits t ON pd.trait_id = t.id -- Join to get trait names
        JOIN
            trials tr ON pd.trial_id = tr.id
        WHERE
            -- Add your filtering conditions here, combined with AND
            -- You can uncomment and modify the examples below

            -- Filter by one or more years (use IN for multiple specific years)
            -- tr.year IN (2023, 2024)
            -- OR filter by a range of years (inclusive)
            -- tr.year BETWEEN 2020 AND 2025

            -- Filter by one or more seasons
            -- AND tr.season IN ('Spring', 'Autumn')

            -- Filter by one or more harvests
            -- AND tr.harvest IN ('Main', 'Ratoon')

            -- Filter by one or more sites
            -- AND tr.site IN ('SiteA', 'SiteB', 'SiteC')

            -- Filter by one or more entry names
            -- AND e.name IN ('HybridX', 'VarietyY')

            -- Filter by one or more populations
            -- AND e.population IN ('Elite', 'Breeding Pool')

            -- You can also filter by specific traits
            -- AND t.name = 'Yield'
            -- AND t.name IN ('Yield', 'Height', 'Flowering Time')

            -- Example combining multiple filters:
            -- tr.year = 2024
            -- AND tr.site = 'SiteA'
            -- AND e.population IN ('Elite', 'Advanced')
            -- AND t.name = 'Yield'
   """ 
end


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
