module GenomicBreedingApp

# using Genie, Genie.Router, Genie.Renderer.Html, Genie.Auth, Genie.Session, Genie.Requests, Genie.FileUtils
using DotEnv, LibPQ
using GenieFramework
using DataFrames, StatsBase
using GenomicBreedingCore, GenomicBreedingIO
@genietools

# Load configurations
DotEnv.load!(joinpath(homedir(), ".env"))

# Database connection
# $ pg_ctl -D $CONDA_PREFIX/pgsql_data start

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

function upload(; fname::String, sep::String = "\t", verbose::Bool = false)
    # genomes = GenomicBreedingCore.simulategenomes(n=10, verbose=false); 
    # trials, _ = GenomicBreedingCore.simulatetrials(genomes=genomes, verbose=false); 
    # fname = writedelimited(trials); sep = "\t"; verbose = true
    X = try
        readdelimited(Genomes, fname=fname, sep=sep, verbose=verbose)
    catch
        try
            readvcf(fname=fname)
        catch
            X = try
                readdelimited(Phenomes, fname=fname, sep=sep, verbose=verbose)
            catch
                readdelimited(Trials, fname=fname, sep=sep, verbose=verbose)
            end
            tabularise(X)
        end
    end
    if isa(X, Genomes)
        # Genomes
    else
        # Trials and Phenomes
        expression = """
            INSERT INTO trials (year, season, site)
            VALUES (\$1, \$2, \$3)
            RETURNING id;
        """
        res = execute(conn, expression, [2025, X.seasons[1], X.sites[1]])
        res

    end
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
