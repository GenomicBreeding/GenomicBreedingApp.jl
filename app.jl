module GenomicBreedingApp

using DotEnv, LibPQ, Tables
using GenieFramework
using DataFrames, StatsBase
using GenomicBreedingCore, GenomicBreedingIO
using Suppressor, ProgressMeter
# Load database credentials
DotEnv.load!(joinpath(homedir(), ".env"))
# Load functions
include("src/connection.jl")
include("src/upload.jl")
include("src/download.jl")
# Import all necessary GenieFramework.jl components
@genietools
# Define the reactive parts of the app (i.e. the inputs and outputs)
@app begin
    @in tab_selected_main = "search_and_download"
    @in tab_selected_queries = "base_tables"

    #####################################################################################################################
    # Base  tables
    df_analyses = string.(sort(querytable("analyses", fields=["name", "description"])))
    df_entries = string.(sort(querytable("entries", fields=["name", "description"])))
    df_traits = string.(sort(querytable("traits", fields=["name", "description"])))
    df_trials = string.(sort(querytable("trials", fields=["year", "season", "harvest", "site", "description"])))
    df_layouts = string.(sort(querytable("layouts", fields=["replication", "block", "row", "col"])))

    @out table_base_analyses = DataTable(df_analyses)
    @in table_base_analyses_filter = ""

    @out table_base_traits = DataTable(df_traits)
    @in table_base_traits_filter = ""

    @out table_base_entries = DataTable(df_entries)
    @in table_base_entries_filter = ""

    @out table_base_trials = DataTable(df_trials)
    @in table_base_trials_filter = ""

    @out table_base_layouts = DataTable(df_layouts)
    @in table_base_layouts_filter = ""
    #####################################################################################################################
    # Analyses
    analyses_list = df_analyses.name
    @in analyses_filter_text = ""             # Input from the text field
    @in analyses_selected_options::Union{Nothing, Vector{String}} = nothing # Input from the select component
    @in analyses_filtered_options = analyses_list   # Output/state: starts with all options
    @onchange analyses_filter_text begin
        search_term = lowercase(analyses_filter_text)
        if isempty(search_term)
            analyses_filtered_options = analyses_list
        else
            analyses_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), analyses_list)
        end
    end
    @out table_query_analyses = DataTable()
    @in table_query_analyses_filter = ""
    @in query_analyses = false
    @out progress_analyses = false
    @onbutton query_analyses begin
        if isnothing(analyses_selected_options)
            analyses_selected_options = analyses_list
        end
        progress_analyses = true
        table_query_analyses = DataTable(queryanalyses(analyses=analyses_selected_options, verbose=true))
        progress_analyses = false
    end
    #####################################################################################################################
    # Species
    species_list = df_entries.name
    @in species_filter_text = ""             # Input from the text field
    @in species_selected_options::Union{Nothing, Vector{String}} = nothing
    @in species_filtered_options = species_list   # Output/state: starts with all options
    @onchange species_filter_text begin
        search_term = lowercase(species_filter_text)
        if isempty(search_term)
            species_filtered_options = species_list
        else
            species_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), species_list)
        end
    end
    # Classifications
    classifications_list = df_entries.name
    @in classifications_filter_text = ""             # Input from the text field
    @in classifications_selected_options::Union{Nothing, Vector{String}} = nothing
    @in classifications_filtered_options = classifications_list   # Output/state: starts with all options
    @onchange classifications_filter_text begin
        search_term = lowercase(classifications_filter_text)
        if isempty(search_term)
            classifications_filtered_options = classifications_list
        else
            classifications_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), classifications_list)
        end
    end
    # Populations
    populations_list = df_entries.name
    @in populations_filter_text = ""             # Input from the text field
    @in populations_selected_options::Union{Nothing, Vector{String}} = nothing
    @in populations_filtered_options = populations_list   # Output/state: starts with all options
    @onchange populations_filter_text begin
        search_term = lowercase(populations_filter_text)
        if isempty(search_term)
            populations_filtered_options = populations_list
        else
            populations_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), populations_list)
        end
    end
    # Entries
    entries_list = df_entries.name
    @in entries_filter_text = ""             # Input from the text field
    @in entries_selected_options::Union{Nothing, Vector{String}} = nothing
    @in entries_filtered_options = entries_list   # Output/state: starts with all options
    @onchange entries_filter_text begin
        search_term = lowercase(entries_filter_text)
        if isempty(search_term)
            entries_filtered_options = entries_list
        else
            entries_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), entries_list)
        end
    end
    # Traits
    traits_list = df_traits.name
    @in traits_filter_text = ""             # Input from the text field
    @in traits_selected_options::Union{Nothing, Vector{String}} = nothing
    @in traits_filtered_options = traits_list   # Output/state: starts with all options
    @onchange traits_filter_text begin
        search_term = lowercase(traits_filter_text)
        if isempty(search_term)
            traits_filtered_options = traits_list
        else
            traits_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), traits_list)
        end
    end
    # Years
    years_list = sort(unique(df_trials.year))
    @in years_filter_text = ""             # Input from the text field
    @in years_selected_options::Union{Nothing, Vector{String}} = nothing
    @in years_filtered_options = years_list   # Output/state: starts with all options
    @onchange years_filter_text begin
        search_term = lowercase(years_filter_text)
        if isempty(search_term)
            years_filtered_options = years_list
        else
            years_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), years_list)
        end
    end
    # Seasons
    seasons_list = sort(unique(df_trials.season))
    @in seasons_filter_text = ""             # Input from the text field
    @in seasons_selected_options::Union{Nothing, Vector{String}} = nothing
    @in seasons_filtered_options = seasons_list   # Output/state: starts with all options
    @onchange seasons_filter_text begin
        search_term = lowercase(seasons_filter_text)
        if isempty(search_term)
            seasons_filtered_options = seasons_list
        else
            seasons_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), seasons_list)
        end
    end
    # Harvests
    harvests_list = sort(unique(df_trials.harvest))
    @in harvests_filter_text = ""             # Input from the text field
    @in harvests_selected_options::Union{Nothing, Vector{String}} = nothing
    @in harvests_filtered_options = harvests_list   # Output/state: starts with all options
    @onchange harvests_filter_text begin
        search_term = lowercase(harvests_filter_text)
        if isempty(search_term)
            harvests_filtered_options = harvests_list
        else
            harvests_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), harvests_list)
        end
    end
    # Sites
    sites_list = sort(unique(df_trials.site))
    @in sites_filter_text = ""             # Input from the text field
    @in sites_selected_options::Union{Nothing, Vector{String}} = nothing
    @in sites_filtered_options = sites_list   # Output/state: starts with all options
    @onchange sites_filter_text begin
        search_term = lowercase(sites_filter_text)
        if isempty(search_term)
            sites_filtered_options = sites_list
        else
            sites_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), sites_list)
        end
    end
    # Replications
    replications_list = sort(unique(df_layouts.replication))
    @in replications_filter_text = ""             # Input from the text field
    @in replications_selected_options::Union{Nothing, Vector{String}} = nothing
    @in replications_filtered_options = replications_list   # Output/state: starts with all options
    @onchange replications_filter_text begin
        search_term = lowercase(replications_filter_text)
        if isempty(search_term)
            replications_filtered_options = replications_list
        else
            replications_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), replications_list)
        end
    end
    # Blocks
    blocks_list = sort(unique(df_layouts.block))
    @in blocks_filter_text = ""             # Input from the text field
    @in blocks_selected_options::Union{Nothing, Vector{String}} = nothing
    @in blocks_filtered_options = blocks_list   # Output/state: starts with all options
    @onchange blocks_filter_text begin
        search_term = lowercase(blocks_filter_text)
        if isempty(search_term)
            blocks_filtered_options = blocks_list
        else
            blocks_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), blocks_list)
        end
    end
    # Rows
    rows_list = sort(unique(df_layouts.row))
    @in rows_filter_text = ""             # Input from the text field
    @in rows_selected_options::Union{Nothing, Vector{String}} = nothing
    @in rows_filtered_options = rows_list   # Output/state: starts with all options
    @onchange rows_filter_text begin
        search_term = lowercase(rows_filter_text)
        if isempty(search_term)
            rows_filtered_options = rows_list
        else
            rows_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), rows_list)
        end
    end
    # Columns
    cols_list = sort(unique(df_layouts.col))
    @in cols_filter_text = ""             # Input from the text field
    @in cols_selected_options::Union{Nothing, Vector{String}} = nothing
    @in cols_filtered_options = cols_list   # Output/state: starts with all options
    @onchange cols_filter_text begin
        search_term = lowercase(cols_filter_text)
        if isempty(search_term)
            cols_filtered_options = cols_list
        else
            cols_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), cols_list)
        end
    end
    @out table_query_entries = DataTable()
    @in table_query_entries_filter = ""
    @in query_entries = false
    @out progress_entries = false
    @onbutton query_entries begin
        if isnothing(traits_selected_options)
            traits_selected_options = traits_list
        end
        species = isnothing(species_selected_options) ? missing : species_selected_options
        classifications = isnothing(classifications_selected_options) ? missing : classifications_selected_options
        populations = isnothing(populations_selected_options) ? missing : populations_selected_options
        entries = isnothing(entries_selected_options) ? missing : entries_selected_options
        years = isnothing(years_selected_options) ? missing : years_selected_options
        seasons = isnothing(seasons_selected_options) ? missing : seasons_selected_options
        harvests = isnothing(harvests_selected_options) ? missing : harvests_selected_options
        sites = isnothing(sites_selected_options) ? missing : sites_selected_options
        blocks = isnothing(blocks_selected_options) ? missing : blocks_selected_options
        rows = isnothing(rows_selected_options) ? missing : rows_selected_options
        cols = isnothing(cols_selected_options) ? missing : cols_selected_options
        replications = isnothing(replications_selected_options) ? missing : replications_selected_options
        progress_entries = true
        table_query_entries = DataTable(querytrialsandphenomes(
            traits = traits_selected_options,
            species = species,
            classifications = classifications,
            populations = populations,
            entries = entries,
            years = years,
            seasons = seasons,
            harvests = harvests,
            sites = sites,
            blocks = blocks,
            rows = rows,
            cols = cols,
            replications = replications,
            verbose = true,
        ))
        progress_entries = false
    end
end




function uiheader()
    heading("GenomicBreedingApp", class = "bg-green-1")
end

function uibasetables()
    [
        expansionitem(label="Analyses", [
            table(
                :table_base_analyses,
                flat = false,
                bordered = true,
                var"row-key" = "name",
                filter = :table_base_analyses_filter,
                template(
                    var"v-slot:top-right" = "",
                    textfield(
                        "",
                        :table_base_analyses_filter,
                        dense = true,
                        debounce = "300",
                        placeholder = "Search",
                        [template(var"v-slot:append" = true, icon("search"))],
                    ),
                ),
            ),
        ]),
        expansionitem(label="Traits", [
            table(
                :table_base_traits,
                flat = false,
                bordered = true,
                var"row-key" = "name",
                filter = :table_base_traits_filter,
                template(
                    var"v-slot:top-right" = "",
                    textfield(
                        "",
                        :table_base_traits_filter,
                        dense = true,
                        debounce = "300",
                        placeholder = "Search",
                        [template(var"v-slot:append" = true, icon("search"))],
                    ),
                ),
            ),
        ]),
        expansionitem(label="Entries", [
            table(
                :table_base_entries,
                flat = false,
                bordered = true,
                var"row-key" = "name",
                filter = :table_base_entries_filter,
                template(
                    var"v-slot:top-right" = "",
                    textfield(
                        "",
                        :table_base_entries_filter,
                        dense = true,
                        debounce = "300",
                        placeholder = "Search",
                        [template(var"v-slot:append" = true, icon("search"))],
                    ),
                ),
            ),
        ]),
        expansionitem(label="Trials", [
            table(
                :table_base_trials,
                flat = false,
                bordered = true,
                var"row-key" = "name",
                filter = :table_base_trials_filter,
                template(
                    var"v-slot:top-right" = "",
                    textfield(
                        "",
                        :table_base_trials_filter,
                        dense = true,
                        debounce = "300",
                        placeholder = "Search",
                        [template(var"v-slot:append" = true, icon("search"))],
                    ),
                ),
            ),
        ]),
        expansionitem(label="Layouts", [
            table(
                :table_base_layouts,
                flat = false,
                bordered = true,
                var"row-key" = "name",
                filter = :table_base_layouts_filter,
                template(
                    var"v-slot:top-right" = "",
                    textfield(
                        "",
                        :table_base_layouts_filter,
                        dense = true,
                        debounce = "300",
                        placeholder = "Search",
                        [template(var"v-slot:append" = true, icon("search"))],
                    ),
                ),
            ),
        ]),
    ]
end

function uiqueryanalyses()
    [
        textfield(
            "Analyses",
            @bind(:analyses_filter_text),
            outlined=true,
            dense=true,
            clearable=true,
            rounded=true,
        ),
        Stipple.select(
            :analyses_selected_options,
            options=:analyses_filtered_options,
            multiple = true,
            clearable = true,
            usechips = true,
            counter = true,
            dense = true,
        ),
        p("\t"),
        btn(
            "Query",
            @click(:query_analyses),
            # @click("query_analyses = true"),
            # loading = :query_analyses,
            # percentage = :ButtonProgress_progress,
            color = "green",
        ),
        spinner(:hourglass, color = "green", size = "3em", @iif("progress_analyses == true")),
        separator(color = "primary"),
        table(
            :table_query_analyses,
            pagination = :TablePagination_tpagination,
            flat = true,
            bordered = true,
            title = "Results",
            var"row-key" = ["species", "classification", "name", "population"],
            filter = :table_query_analyses_filter,
            template(
                var"v-slot:top-right" = "",
                textfield(
                    "",
                    :table_test_filter,
                    dense = true,
                    debounce = "300",
                    placeholder = "Search",
                    [template(var"v-slot:append" = true, icon("search"))],
                ),
            ),
        ),
    ]
end

function uisqueryentries()
    [
        row([
            column(size = 2, [
                textfield(
                    "Species",
                    @bind(:species_filter_text),
                    outlined=true,
                    dense=true,
                    clearable=true,
                    rounded=true,
                ),
                Stipple.select(
                    :species_selected_option,
                    options=:species_filtered_options,
                    multiple = true,
                    clearable = true,
                    usechips = true,
                    counter = true,
                    dense = true,
                ),
                textfield(
                    "Classifications",
                    @bind(:classifications_filter_text),
                    outlined=true,
                    dense=true,
                    clearable=true,
                    rounded=true,
                ),
                Stipple.select(
                    :classifications_selected_option,
                    options=:classifications_filtered_options,
                    multiple = true,
                    clearable = true,
                    usechips = true,
                    counter = true,
                    dense = true,
                ),
                textfield(
                    "Populations",
                    @bind(:populations_filter_text),
                    outlined=true,
                    dense=true,
                    clearable=true,
                    rounded=true,
                ),
                Stipple.select(
                    :populations_selected_option,
                    options=:populations_filtered_options,
                    multiple = true,
                    clearable = true,
                    usechips = true,
                    counter = true,
                    dense = true,
                ),
            ]),
            column(size = 1),
            column(size = 2, [
                textfield(
                    "Traits",
                    @bind(:traits_filter_text),
                    outlined=true,
                    dense=true,
                    clearable=true,
                    rounded=true,
                ),
                Stipple.select(
                    :traits_selected_option,
                    options=:traits_filtered_options,
                    multiple = true,
                    clearable = true,
                    usechips = true,
                    counter = true,
                    dense = true,
                ),
                textfield(
                    "Years",
                    @bind(:years_filter_text),
                    outlined=true,
                    dense=true,
                    clearable=true,
                    rounded=true,
                ),
                Stipple.select(
                    :years_selected_option,
                    options=:years_filtered_options,
                    multiple = true,
                    clearable = true,
                    usechips = true,
                    counter = true,
                    dense = true,
                ),
                textfield(
                    "Seasons",
                    @bind(:seasons_filter_text),
                    outlined=true,
                    dense=true,
                    clearable=true,
                    rounded=true,
                ),
                Stipple.select(
                    :seasons_selected_option,
                    options=:seasons_filtered_options,
                    multiple = true,
                    clearable = true,
                    usechips = true,
                    counter = true,
                    dense = true,
                ),
            ]),
            column(size = 1),
            column(size = 2, [
                    textfield(
                    "Harvests",
                    @bind(:harvests_filter_text),
                    outlined=true,
                    dense=true,
                    clearable=true,
                    rounded=true,
                ),
                Stipple.select(
                    :harvests_selected_option,
                    options=:harvests_filtered_options,
                    multiple = true,
                    clearable = true,
                    usechips = true,
                    counter = true,
                    dense = true,
                ),
                textfield(
                    "Sites",
                    @bind(:sites_filter_text),
                    outlined=true,
                    dense=true,
                    clearable=true,
                    rounded=true,
                ),
                Stipple.select(
                    :sites_selected_option,
                    options=:sites_filtered_options,
                    multiple = true,
                    clearable = true,
                    usechips = true,
                    counter = true,
                    dense = true,
                ),
                textfield(
                    "Replications",
                    @bind(:replications_filter_text),
                    outlined=true,
                    dense=true,
                    clearable=true,
                    rounded=true,
                ),
                Stipple.select(
                    :replications_selected_option,
                    options=:replications_filtered_options,
                    multiple = true,
                    clearable = true,
                    usechips = true,
                    counter = true,
                    dense = true,
                ),
            ]),
            column(size = 1),
            column(size = 2, [
                textfield(
                    "Blocks",
                    @bind(:blocks_filter_text),
                    outlined=true,
                    dense=true,
                    clearable=true,
                    rounded=true,
                ),
                Stipple.select(
                    :blocks_selected_option,
                    options=:blocks_filtered_options,
                    multiple = true,
                    clearable = true,
                    usechips = true,
                    counter = true,
                    dense = true,
                ),
                textfield(
                    "Rows",
                    @bind(:rows_filter_text),
                    outlined=true,
                    dense=true,
                    clearable=true,
                    rounded=true,
                ),
                Stipple.select(
                    :rows_selected_option,
                    options=:rows_filtered_options,
                    multiple = true,
                    clearable = true,
                    usechips = true,
                    counter = true,
                    dense = true,
                ),
                textfield(
                    "Columns",
                    @bind(:cols_filter_text),
                    outlined=true,
                    dense=true,
                    clearable=true,
                    rounded=true,
                ),
                Stipple.select(
                    :cols_selected_option,
                    options=:cols_filtered_options,
                    multiple = true,
                    clearable = true,
                    usechips = true,
                    counter = true,
                    dense = true,
                ),
            ]),
        ]),
        toggle("Include phenotype data?", :phenotype_data, color = "green"),
        toggle("Include genotype data?", :genotype_data, color = "blue"),
        p("\t"),
        btn(
            "Query",
            @click(:query_entries),
            # @click("query_entries = true"),
            # loading = :query_entries,
            # percentage = :ButtonProgress_progress,
            color = "green",
        ),
        spinner(:hourglass, color = "green", size = "3em", @iif("progress_entries == true")),
        separator(color = "primary"),

        table(
            :table_query_entries,
            flat = true,
            bordered = true,
            title = "Entries",
            var"row-key" = "name",
            filter = :table_query_entries_filter,
            template(
                var"v-slot:top-right" = "",
                textfield(
                    "",
                    :table_query_entries_filter,
                    dense = true,
                    debounce = "300",
                    placeholder = "Search",
                    [template(var"v-slot:append" = true, icon("search"))],
                ),
            ),
        ),
    ]
end

function uisearchanddownload()
    [
        tabgroup(
            :tab_selected_queries,
            align = "justify",
            inlinelabel = true,
            class = "bg-primary text-white shadow-2",
            [
                tab(
                    name = "base_tables",
                    label = "Base Tables",
                ),
                tab(name = "analyses_queries",
                    label = "Analyses Queries"
                ),
                tab(name = "entries_queries",
                    label = "Entries/Trials Queries"
                ),
            ],
        ),
        tabpanels(
            :tab_selected_queries,
            animated = true,
            var"transition-prev" = "scale",
            var"transition-next" = "scale",
            [
                tabpanel(name = "base_tables", uibasetables()),
                tabpanel(name = "analyses_queries", uiqueryanalyses()),
                tabpanel(name = "entries_queries", uisqueryentries()),
            ],
        ),
    ]
end

function ui()
    [
        uiheader(),
        tabgroup(
            :tab_selected_main,
            align = "justify",
            inlinelabel = true,
            class = "bg-primary text-white shadow-2",
            [
                tab(
                    name = "search_and_download",
                    icon = "search",
                    label = "Search/Download",
                ),
                tab(name = "analyse_and_plot", icon = "analytics", label = "Analyse/Plot"),
                tab(
                    name = "upload_and_validate",
                    icon = "upload",
                    label = "Upload/Validate",
                ),
            ],
        ),
        tabpanels(
            :tab_selected_main,
            animated = true,
            var"transition-prev" = "scale",
            var"transition-next" = "scale",
            [
                tabpanel(name = "search_and_download", uisearchanddownload()),
                tabpanel(name = "analyse_and_plot", [p("Analyse/Plot Tab")]),
                tabpanel(name = "upload_and_validate", [p("Upload/Validate Tab")]),
            ],
        ),
    ]
end

@page("/", ui)
end
