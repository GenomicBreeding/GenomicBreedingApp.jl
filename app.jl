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
    @in tab_selected = "search_and_download"

    df_analyses = string.(sort(querytable("analyses", fields=["name", "description"])))
    df_entries = string.(sort(querytable("entries", fields=["name", "description"])))
    df_traits = string.(sort(querytable("traits", fields=["name", "description"])))
    df_trials = string.(sort(querytable("trials", fields=["year", "season", "harvest", "site", "description"])))
    df_layouts = string.(sort(querytable("layouts", fields=["replication", "block", "row", "col"])))

    # Analyses
    analyses_list = df_analyses.name
    @in analyses_filter_text = ""             # Input from the text field
    @in analyses_selected_option::Union{String, Nothing} = nothing # Input from the select component
    @in analyses_filtered_options = analyses_list   # Output/state: starts with all options
    @onchange analyses_filter_text begin
        search_term = lowercase(analyses_filter_text)
        if isempty(search_term)
            analyses_filtered_options = analyses_list
        else
            analyses_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), analyses_list)
        end
    end
    # Entries
    entries_list = df_entries.name
    @in entries_filter_text = ""             # Input from the text field
    @in entries_selected_option::Union{String, Nothing} = nothing # Input from the select component
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
    @in traits_selected_option::Union{String, Nothing} = nothing # Input from the select component
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
    @in years_selected_option::Union{String, Nothing} = nothing # Input from the select component
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
    @in seasons_selected_option::Union{String, Nothing} = nothing # Input from the select component
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
    @in harvests_selected_option::Union{String, Nothing} = nothing # Input from the select component
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
    @in sites_selected_option::Union{String, Nothing} = nothing # Input from the select component
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
    @in replications_selected_option::Union{String, Nothing} = nothing # Input from the select component
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
    @in blocks_selected_option::Union{String, Nothing} = nothing # Input from the select component
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
    @in rows_selected_option::Union{String, Nothing} = nothing # Input from the select component
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
    @in cols_selected_option::Union{String, Nothing} = nothing # Input from the select component
    @in cols_filtered_options = cols_list   # Output/state: starts with all options
    @onchange cols_filter_text begin
        search_term = lowercase(cols_filter_text)
        if isempty(search_term)
            cols_filtered_options = cols_list
        else
            cols_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), cols_list)
        end
    end
    



    @in phenotype_data = false
    @in genotype_data = false
  
    @in ButtonProgress_process = false
    # @in ButtonProgress_progress = 0.0
    @onbutton ButtonProgress_process begin
    #     for ButtonProgress_progress = 1:10
    #         @show ButtonProgress_progress
            sleep(5.0)
    #     end
    #     ButtonProgress_progress = 0.0
    end





    @out TableSearch_data = DataTable(df_entries)
    @in TableSearch_dfilter = ""

    @out TableSearch_data_analyses = DataTable(df_analyses)
    @in TableSearch_dfilter_analyses = ""

    @out TableSearch_data_traits = DataTable(df_traits)
    @in TableSearch_dfilter_traits = ""

    @out TableSearch_data_entries = DataTable(df_entries)
    @in TableSearch_dfilter_entries = ""

    @out TableSearch_data_trials = DataTable(df_trials)
    @in TableSearch_dfilter_trials = ""

    @out TableSearch_data_layouts = DataTable(df_layouts)
    @in TableSearch_dfilter_layouts = ""

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
        row([
            column(size = 2, [
                textfield(
                    "Analyses",
                    @bind(:analyses_filter_text),
                    outlined=true,
                    dense=true,
                    clearable=true,
                    rounded=true,
                ),
                Stipple.select(
                    :analyses_selected_option,
                    options=:analyses_filtered_options,
                    multiple = true,
                    clearable = true,
                    usechips = true,
                    counter = true,
                    dense = true,
                ),
                textfield(
                    "Entries",
                    @bind(:entries_filter_text),
                    outlined=true,
                    dense=true,
                    clearable=true,
                    rounded=true,
                ),
                Stipple.select(
                    :entries_selected_option,
                    options=:entries_filtered_options,
                    multiple = true,
                    clearable = true,
                    usechips = true,
                    counter = true,
                    dense = true,
                ),
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
            ]),
            column(size = 1),
            column(size = 2, [
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
            ]),
            column(size = 1),
            column(size = 2, [
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
            ]),
            column(size = 1),
            column(size = 2, [
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
        
        toggle("Phenotype Data", :phenotype_data, color = "green"),
        toggle("Genotype Data", :genotype_data, color = "blue"),
        p("\t"),
        btn(
            "Query",
            # @click(:ButtonProgress_process),
            @click("ButtonProgress_process = true"),
            # loading = :ButtonProgress_process,
            # percentage = :ButtonProgress_progress,
            color = "green",
        ),
        spinner(:hourglass, color = "green", size = "3em", loading = :ButtonProgress_process),
        separator(color = "primary"),

        table(
            :TableSearch_data,
            flat = true,
            bordered = true,
            title = "Entries",
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
        ),




        separator(color = "primary"),
        p("Main tables", style="font-weight: bold; font-size: 24px;"),
        expansionitem(label="Analyses", [
            table(
                :TableSearch_data_analyses,
                title="Analyses",
                flat = false,
                bordered = true,
                var"row-key" = "name",
                filter = :TableSearch_dfilter_analyses,
                hideheader = "",
                template(
                    var"v-slot:top-right" = "",
                    textfield(
                        "",
                        :TableSearch_dfilter_analyses,
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
                :TableSearch_data_traits,
                title="Traits",
                flat = false,
                bordered = true,
                var"row-key" = "name",
                filter = :TableSearch_dfilter_traits,
                hideheader = "",
                template(
                    var"v-slot:top-right" = "",
                    textfield(
                        "",
                        :TableSearch_dfilter_traits,
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
                :TableSearch_data_entries,
                title="Entries",
                flat = false,
                bordered = true,
                var"row-key" = "name",
                filter = :TableSearch_dfilter_entries,
                hideheader = "",
                template(
                    var"v-slot:top-right" = "",
                    textfield(
                        "",
                        :TableSearch_dfilter_entries,
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
                :TableSearch_data_trials,
                title="Trials",
                flat = false,
                bordered = true,
                var"row-key" = "name",
                filter = :TableSearch_dfilter_trials,
                hideheader = "",
                template(
                    var"v-slot:top-right" = "",
                    textfield(
                        "",
                        :TableSearch_dfilter_trials,
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
                :TableSearch_data_layouts,
                title="Layouts",
                flat = false,
                bordered = true,
                var"row-key" = "name",
                filter = :TableSearch_dfilter_layouts,
                hideheader = "",
                template(
                    var"v-slot:top-right" = "",
                    textfield(
                        "",
                        :TableSearch_dfilter_layouts,
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

function ui()
    [
        uiheader(),
        tabgroup(
            :tab_selected,
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
    ]
end

@page("/", ui)
end
