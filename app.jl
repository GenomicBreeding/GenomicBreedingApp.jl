module GenomicBreedingApp

using StatsBase, DataFrames, Tables, CSV, StippleDownloads
using PlotlyBase
using GenieFramework
using GenomicBreedingCore, GenomicBreedingIO
# Make sure the PostgreSQL database is running (see https://github.com/GenomicBreeding/GenomicBreedingDB.jl)
using GenomicBreedingDB, DotEnv
# Load database credentials
DotEnv.load!(joinpath(homedir(), ".env"))
# Import all necessary GenieFramework.jl components
@genietools
# Define the reactive parts of the app (i.e. the inputs and outputs)
@app begin
    @in tab_selected_main = "search_and_download"
    @in tab_selected_queries = "base_tables"
    @in tab_selected_plot = "histogram"

#####################################################################################################################
# Base tables
    df_analyses = string.(sort(querytable("analyses", fields=["name", "description"])))
    df_entries = string.(sort(querytable("entries", fields=["name", "species", "classification", "population", "description"])))
    df_traits = string.(sort(querytable("traits", fields=["name", "description"])))
    df_trials = string.(sort(querytable("trials", fields=["year", "season", "harvest", "site", "description"])))
    df_layouts = string.(sort(querytable("layouts", fields=["replication", "block", "row", "col"])))

    @out table_base_analyses = DataTable(df_analyses)
    @in table_base_analyses_filter = ""
    @event download_base_analyses begin
        println("Downloading base analyses")
        download_binary(__model__, df_to_io(table_base_analyses.data), "analyses_table.txt", )
    end

    @out table_base_traits = DataTable(df_traits)
    @in table_base_traits_filter = ""
    @event download_base_traits begin
        download_binary(__model__, df_to_io(table_base_traits.data), "traits_table.txt", )
    end

    @out table_base_entries = DataTable(df_entries)
    @in table_base_entries_filter = ""
    @event download_base_entries begin
        download_binary(__model__, df_to_io(table_base_entries.data), "entries_table.txt", )
    end

    @out table_base_trials = DataTable(df_trials)
    @in table_base_trials_filter = ""
    @event download_base_trials begin
        download_binary(__model__, df_to_io(table_base_trials.data), "trials_table.txt", )
    end

    @out table_base_layouts = DataTable(df_layouts)
    @in table_base_layouts_filter = ""
    @event download_base_layouts begin
        download_binary(__model__, df_to_io(table_base_layouts.data), "layouts_table.txt", )
    end

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
        analyses::Vector{Union{String, Missing}} = if isnothing(analyses_selected_options)
            [x == "missing" ? missing : x for x in analyses_list]
        else
            analyses_selected_options
        end
        progress_analyses = true
        table_query_analyses = DataTable(queryanalyses(analyses=analyses, verbose=true))
        @show table_query_analyses.data
        progress_analyses = false
    end
    @event download_analyses begin
        download_binary(__model__, df_to_io(table_query_analyses.data), "analyses_data.txt", )
    end
#####################################################################################################################
# Entries-by-Trials-by-Layouts
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
    # Species
    species_list = sort(unique(df_entries.species))
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
    classifications_list = sort(unique(df_entries.classification))
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
    populations_list = sort(unique(df_entries.population))
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
    # Query
    @in phenotype_data = "yes"
    @in genotype_data = "no" # TODO: use when genotype data tables have been added
    @out table_query_entries = DataTable()
    @in table_query_entries_filter = ""
    @in query_entries = false
    @out progress_entries = false
    @onbutton query_entries begin
        if phenotype_data == "yes"
            progress_entries = true
            traits::Vector{String} = isnothing(traits_selected_options) ? traits_list : traits_selected_options
            species::Vector{Union{String, Missing}} = isnothing(species_selected_options) ? [x == "missing" ? missing : x for x in species_list] : [x == "missing" ? missing : x for x in species_selected_options]
                classifications::Vector{Union{String, Missing}} = isnothing(classifications_selected_options) ? [x == "missing" ? missing : x for x in classifications_list] : [x == "missing" ? missing : x for x in classifications_selected_options]
                populations::Vector{Union{String, Missing}} = isnothing(populations_selected_options) ? [x == "missing" ? missing : x for x in populations_list] : [x == "missing" ? missing : x for x in populations_selected_options]
                entries::Vector{Union{String, Missing}} = isnothing(entries_selected_options) ? [x == "missing" ? missing : x for x in entries_list] : [x == "missing" ? missing : x for x in entries_selected_options]
                years::Vector{Union{Missing, String}} = isnothing(years_selected_options) ? [x == "missing" ? missing : x for x in years_list] : [x == "missing" ? missing : x for x in years_selected_options]
                seasons::Vector{Union{String, Missing}} = isnothing(seasons_selected_options) ? [x == "missing" ? missing : x for x in seasons_list] : [x == "missing" ? missing : x for x in seasons_selected_options]
                harvests::Vector{Union{String, Missing}} = isnothing(harvests_selected_options) ? [x == "missing" ? missing : x for x in harvests_list] : [x == "missing" ? missing : x for x in harvests_selected_options]
                sites::Vector{Union{String, Missing}} = isnothing(sites_selected_options) ? [x == "missing" ? missing : x for x in sites_list] : [x == "missing" ? missing : x for x in sites_selected_options]
                replications::Vector{Union{String, Missing}} = isnothing(replications_selected_options) ? [x == "missing" ? missing : x for x in replications_list] : [x == "missing" ? missing : x for x in replications_selected_options]
                blocks::Vector{Union{String, Missing}} = isnothing(blocks_selected_options) ? [x == "missing" ? missing : x for x in blocks_list] : [x == "missing" ? missing : x for x in blocks_selected_options]
                rows::Vector{Union{String, Missing}} = isnothing(rows_selected_options) ? [x == "missing" ? missing : x for x in rows_list] : [x == "missing" ? missing : x for x in rows_selected_options]            
                cols::Vector{Union{String, Missing}} = isnothing(cols_selected_options) ? [x == "missing" ? missing : x for x in cols_list] : [x == "missing" ? missing : x for x in cols_selected_options]            
                table_query_entries = DataTable(querytrialsandphenomes(
                    traits = traits, # cannot be missing
                    species = species,
                    classifications = classifications,
                    populations = populations,
                    entries = entries,
                    years = years,
                    seasons = seasons,
                    harvests = harvests,
                    sites = sites,
                    replications = replications,
                    blocks = blocks,
                    rows = rows,
                    cols = cols,
                    verbose = true,
                ))
                progress_entries = false
        else
            table_query_entries = DataTable(DataFrame(var"Phenotypes not requested"="no phenotype data requested"))
        end
        if genotype_data == "yes"
            println("Genotype data query not implemented yet")
        else
            println("No genotype data requested")
        end
    end
    @event download_entries begin
        download_binary(__model__, df_to_io(table_query_entries.data), "entries_data.txt", )
    end
######################################################################################################################
# Plots

    # Initial tables: one for each plot type, i.e. histogram, scatter, boxplot
    df = [
        queryanalyses(analyses=[querytable("analyses").name[1]], verbose=true),
        queryanalyses(analyses=[querytable("analyses").name[1]], verbose=true),
        queryanalyses(analyses=[querytable("analyses").name[1]], verbose=true),
    ]

    # Histograms
    @in selected_table_to_plot_hist = ["analyses"]
    @out choices_tables_to_plot_hist = ["analyses", "trials/entries"]
    @in selected_plot_traits_hist = []
    @out choices_plot_traits_hist = names(df[1])[13:end]
    plots_vector_hist = []
    for t in names(df[1])[13:end]
        push!(plots_vector_hist, PlotlyBase.histogram(x=df[1][!, t]))
    end
    plots_layout_hist = PlotlyBase.Layout(barmode="overlay")
    @out plotdata_hist = plots_vector_hist
    @out plotlayout_hist = plots_layout_hist
    @onchange selected_table_to_plot_hist begin
        selected_plot_traits_hist = []
        choices_plot_traits_hist = []
        df[1] = if selected_table_to_plot_hist == ["analyses"]
            if nrow(table_query_analyses.data) == 0
                println("No data to plot")
                return DataFrame()
            else
                table_query_analyses.data
            end
        elseif selected_table_to_plot_hist == ["trials/entries"]
            if nrow(table_query_entries.data) == 0
                println("No data to plot")
                return DataFrame()
            else
                table_query_entries.data
            end
        else
            println("Unknown table selected")
            return DataFrame()
        end
        choices_plot_traits_hist = if ncol(df[1]) == 0
            ["missing"]
        else
            @show names(df[1])
            names(df[1])[13:end]
        end
    end
    @in plot_table_hist = false
    @onbutton plot_table_hist begin
        println("Plotting histogram")
        plots_vector_hist = []
        for t in selected_plot_traits_hist
            @show t
            @show names(df[1])
            try 
                df[1][!, t]
            catch
                continue
            end
            x = filter(x -> !isnothing(x) && !ismissing(x) && !isinf(x), df[1][!, t])
            if length(x) < 1
                continue
            end
            push!(plots_vector_hist, PlotlyBase.histogram(x=x, name=t))
        end
        plots_layout_hist = PlotlyBase.Layout(barmode="overlay")
        # Update
        plotdata_hist = plots_vector_hist
        plotlayout_hist = plots_layout_hist
    end

    # Scatterplots
    @in selected_table_to_plot_scat = ["analyses"]
    @out choices_tables_to_plot_scat = ["analyses", "trials/entries"]
    @in selected_plot_traits_scat_x = []
    @out choices_plot_traits_scat_x = names(df[2])[13:end]
    @in selected_plot_traits_scat_y = []
    @out choices_plot_traits_scat_y = names(df[2])[13:end]
    plots_vector_scat = []
    x = df[2][:, 13]
    y = df[2][:, end]
    idx = findall(.!ismissing.(x) .&& .!ismissing.(y) .&& .!isnan.(x) .&& .!isnan.(y) .&& .!isinf.(x) .&& .!isinf.(y))
    x = x[idx]
    y = y[idx]
    plots_vector_scat = [PlotlyBase.scatter(x=x, y=y, mode="markers")]
    plots_layout_scat = PlotlyBase.Layout(barmode="overlay")
    @out plotdata_scat = plots_vector_scat
    @out plotlayout_scat = plots_layout_scat
    @onchange selected_table_to_plot_scat begin
        selected_plot_traits_scat_x = []
        choices_plot_traits_scat_x = []
        selected_plot_traits_scat_y = []
        choices_plot_traits_scat_y = []
        df[2] = if selected_table_to_plot_scat == ["analyses"]
            if nrow(table_query_analyses.data) == 0
                println("No data to plot")
                return DataFrame()
            else
                table_query_analyses.data
            end
        elseif selected_table_to_plot_scat == ["trials/entries"]
            if nrow(table_query_entries.data) == 0
                println("No data to plot")
                return DataFrame()
            else
                table_query_entries.data
            end
        else
            println("Unknown table selected")
            return DataFrame()
        end
        choices_plot_traits_scat_x = if ncol(df[2]) == 0
            ["missing"]
        else
            names(df[2])[13:end]
        end
        choices_plot_traits_scat_y = if ncol(df[2]) == 0
            ["missing"]
        else
            names(df[2])[13:end]
        end
    end
    @in plot_table_scat = false
    @onbutton plot_table_scat begin
        println("Plotting scatterplot")
        x = df[2][!, selected_plot_traits_scat_x[1]]
        y = df[2][!, selected_plot_traits_scat_y[1]]
        idx = findall(.!ismissing.(x) .&& .!ismissing.(y) .&& .!isnan.(x) .&& .!isnan.(y) .&& .!isinf.(x) .&& .!isinf.(y))
        hovertext = [
            join(
                filter(x -> !isnothing(x) && split(x, ": ")[end] != "missing", [
                    # Trials and phenomes
                    "name" ∈ names(df[2]) ? string("name: ", df[2].name[i]) : nothing,
                    "population" ∈ names(df[2]) ? string("population: ", df[2].population[i]) : nothing,
                    "year" ∈ names(df[2]) ? string("year: ", df[2].year[i]) : nothing,
                    "season" ∈ names(df[2]) ? string("season: ", df[2].season[i]) : nothing,
                    "site" ∈ names(df[2]) ? string("site: ", df[2].site[i]) : nothing,
                    "harvest" ∈ names(df[2]) ? string("harvest: ", df[2].harvest[i]) : nothing,
                    "replication" ∈ names(df[2]) ? string("replication: ", df[2].replication[i]) : nothing,
                    "block" ∈ names(df[2]) ? string("block: ", df[2].block[i]) : nothing,
                    "row" ∈ names(df[2]) ? string("row: ", df[2].row[i]) : nothing,
                    "column" ∈ names(df[2]) ? string("column: ", df[2].column[i]) : nothing,
                    # CVs
                    "fold" ∈ names(df[2]) ? string("fold: ", df[2].fold[i]) : nothing,
                    string(selected_plot_traits_scat_x[1], ": ", round(x[i], digits=4)),
                    string(selected_plot_traits_scat_y[1], ": ", round(y[i], digits=4))
                ]), "<br>"
            ) for i in idx
        ]
        plots_vector_scat = [PlotlyBase.scatter(
            x=x[idx], 
            y=y[idx], 
            mode="markers", 
            hoverinfo="text", 
            hovertext=hovertext,
        )]
        plots_layout_scat = PlotlyBase.Layout(barmode="overlay")
        # Update
        plotdata_scat = plots_vector_scat
        plotlayout_scat = plots_layout_scat
    end

    # Boxplots
    @in selected_table_to_plot_box = ["analyses"]
    @out choices_tables_to_plot_box = ["analyses", "trials/entries"]
    @in selected_plot_traits_box = []
    @out choices_plot_traits_box = names(df[2])[13:end]
    plots_vector_box = []
    for t in names(df[2])[13:end]
        push!(plots_vector_box, PlotlyBase.histogram(x=df[2][!, t]))
    end
    plots_layout_box = PlotlyBase.Layout(barmode="overlay")
    @out plotdata_box = plots_vector_box
    @out plotlayout_box = plots_layout_box
    @onchange selected_table_to_plot_box begin
        selected_plot_traits_box = []
        choices_plot_traits_box = []
        df[2] = if selected_table_to_plot_box == ["analyses"]
            if nrow(table_query_analyses.data) == 0
                println("No data to plot")
                return DataFrame()
            else
                table_query_analyses.data
            end
        elseif selected_table_to_plot_box == ["trials/entries"]
            if nrow(table_query_entries.data) == 0
                println("No data to plot")
                return DataFrame()
            else
                table_query_entries.data
            end
        else
            println("Unknown table selected")
            return DataFrame()
        end
        choices_plot_traits_box = if ncol(df[2]) == 0
            ["missing"]
        else
            @show names(df[2])
            names(df[2])[13:end]
        end
    end
    @in plot_table_box = false
    @onbutton plot_table_box begin
        println("Plotting scatterplot")
        plots_vector_box = []
        for t in selected_plot_traits_box
            @show t
            @show names(df[2])
            try 
                df[2][!, t]
            catch
                continue
            end
            x = filter(x -> !isnothing(x) && !ismissing(x) && !isinf(x), df[2][!, t])
            if length(x) < 1
                continue
            end
            push!(plots_vector_box, PlotlyBase.histogram(x=x, name=t))
        end
        plots_layout_box = PlotlyBase.Layout(barmode="overlay")
        # Update
        plotdata_box = plots_vector_box
        plotlayout_box = plots_layout_box
    end
end




function uiheader()
    heading("GenomicBreedingApp", class = "bg-green-1")
end

function uibasetables()
    [
        expansionitem(label="Analyses", expandseparator=true, [
            btn("Download Analyses Table", icon = "download", @on(:click, :download_base_analyses), color = "primary", nocaps = true),
            Stipple.table(
                :table_base_analyses,
                flat = false,
                bordered = true,
                var"row-key" = ["name", "description"],
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
        separator(color = "primary"),
        expansionitem(label="Traits", expandseparator=true, [
            btn("Download Traits Table", icon = "download", @on(:click, :download_base_traits), color = "primary", nocaps = true),
            Stipple.table(
                :table_base_traits,
                flat = false,
                bordered = true,
                var"row-key" = ["name", "description"],
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
        separator(color = "primary"),
        expansionitem(label="Entries", expandseparator=true, [
            btn("Download Entries Table", icon = "download", @on(:click, :download_base_entries), color = "primary", nocaps = true),
            Stipple.table(
                :table_base_entries,
                flat = false,
                bordered = true,
                var"row-key" = ["name", "species", "classification", "population"],
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
        separator(color = "primary"),
        expansionitem(label="Trials", expandseparator=true, [
            btn("Download Trials Table", icon = "download", @on(:click, :download_base_trials), color = "primary", nocaps = true),
            Stipple.table(
                :table_base_trials,
                flat = false,
                bordered = true,
                var"row-key" = ["year", "season", "harvest", "site", "description"],
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
        separator(color = "primary"),
        expansionitem(label="Layouts", expandseparator=true, [
            btn("Download Layouts Table", icon = "download", @on(:click, :download_base_layouts), color = "primary", nocaps = true),
            Stipple.table(
                :table_base_layouts,
                flat = false,
                bordered = true,
                var"row-key" = ["replication", "block", "row", "col"],
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
        btn(
            "Query",
            @click(:query_analyses),
            # @click("query_analyses = true"),
            # loading = :query_analyses,
            # percentage = :ButtonProgress_progress,
            color = "green",
        ),
        spinner(:hourglass, color = "green", size = "3em", @iif("progress_analyses == true")),
        p("\t"),
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
            useinput=true, 
            multiple = true,
            clearable = true,
            usechips = true,
            counter = true,
            dense = true,
        ),
        btn("Download", icon = "download", @on(:click, :download_analyses), color = "primary", nocaps = true),
        separator(color = "primary"),
        Stipple.table(
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
        btn(
            "Query",
            @click(:query_entries),
            # @click("query_entries = true"),
            # loading = :query_entries,
            # percentage = :ButtonProgress_progress,
            color = "green",
        ),
        spinner(:hourglass, color = "green", size = "3em", @iif("progress_entries == true")),
        p("\t"),
        textfield(
            "Traits",
            @bind(:traits_filter_text),
            outlined=true,
            dense=true,
            clearable=true,
            rounded=true,
        ),
        Stipple.select(
            :traits_selected_options,
            options=:traits_filtered_options,
            useinput=true, 
            multiple = true,
            clearable = true,
            usechips = true,
            counter = true,
            dense = true,
        ),
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
                    :species_selected_options,
                    options=:species_filtered_options,
                    useinput=true, 
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
                    :classifications_selected_options,
                    options=:classifications_filtered_options,
                    useinput=true, 
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
                    :populations_selected_options,
                    options=:populations_filtered_options,
                    useinput=true, 
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
                    "Entries",
                    @bind(:entries_filter_text),
                    outlined=true,
                    dense=true,
                    clearable=true,
                    rounded=true,
                ),
                Stipple.select(
                    :entries_selected_options,
                    options=:entries_filtered_options,
                    useinput=true, 
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
                    :years_selected_options,
                    options=:years_filtered_options,
                    useinput=true, 
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
                    :seasons_selected_options,
                    options=:seasons_filtered_options,
                    useinput=true, 
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
                    :harvests_selected_options,
                    options=:harvests_filtered_options,
                    useinput=true, 
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
                    :sites_selected_options,
                    options=:sites_filtered_options,
                    useinput=true, 
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
                    :replications_selected_options,
                    options=:replications_filtered_options,
                    useinput=true, 
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
                    :blocks_selected_options,
                    options=:blocks_filtered_options,
                    useinput=true, 
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
                    :rows_selected_options,
                    options=:rows_filtered_options,
                    useinput=true, 
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
                    :cols_selected_options,
                    options=:cols_filtered_options,
                    useinput=true, 
                    multiple = true,
                    clearable = true,
                    usechips = true,
                    counter = true,
                    dense = true,
                ),
            ]),
        ]),
        toggle("Include phenotype data?", :phenotype_data, color = "green", var"true-value" = "yes", var"false-value" = "no",),
        toggle("Include genotype data?", :genotype_data, color = "blue", var"true-value" = "yes", var"false-value" = "no",),
        p("\t"),
        btn("Download", icon = "download", @on(:click, :download_entries), color = "primary", nocaps = true),
        separator(color = "primary"),
        Stipple.table(
            :table_query_entries,
            flat = true,
            bordered = true,
            title = "Entries",
            var"row-key" = ["species", "classification", "name", "population", "year", "season", "harvest", "site", "replication", "block", "row", "col"],
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
            class = "bg-blue text-white shadow-2 size=20",
            activecolorbg = "red",
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

function uiplothist()
    [
        Stipple.select(:selected_table_to_plot_hist, useinput=true, options = :choices_tables_to_plot_hist, label = "Table to plot"),
        Stipple.select(:selected_plot_traits_hist, useinput=true, options = :choices_plot_traits_hist, label = "Traits", multiple=true, usechips=true),
        btn(
            "Plot",
            @click(:plot_table_hist),
            loading = :plot_table_hist,
            color = "green",
        ),
        StipplePlotly.plot(:plotdata_hist, layout=:plotlayout_hist, class="sync_data")
    ]
end

function uiplotscat()
    [
        Stipple.select(:selected_table_to_plot_scat, useinput=true, options = :choices_tables_to_plot_scat, label = "Table to plot"),
        Stipple.select(:selected_plot_traits_scat_x, useinput=true, options = :choices_plot_traits_scat_x, label = "Trait 1", multiple=false, usechips=false),
        Stipple.select(:selected_plot_traits_scat_y, useinput=true, options = :choices_plot_traits_scat_y, label = "Trait 2", multiple=false, usechips=false),
        btn(
            "Plot",
            @click(:plot_table_scat),
            loading = :plot_table_scat,
            color = "green",
        ),
        StipplePlotly.plot(:plotdata_scat, layout=:plotlayout_scat, class="sync_data")
    ]
end

function uiplotbox()
    [
        Stipple.select(:selected_table_to_plot_box, useinput=true, options = :choices_tables_to_plot_box, label = "Table to plot"),
        Stipple.select(:selected_plot_traits_box, useinput=true, options = :choices_plot_traits_box, label = "Traits", multiple=true, usechips=true),
        btn(
            "Plot",
            @click(:plot_table_box),
            loading = :plot_table_box,
            color = "green",
        ),
        StipplePlotly.plot(:plotdata_box, layout=:plotlayout_box, class="sync_data")
    ]
end

function uiplot()
    [
        tabgroup(
            :tab_selected_plot,
            align = "justify",
            inlinelabel = true,
            class = "bg-blue text-white shadow-2 size=20",
            activecolorbg = "red",
            [
                tab(
                    name = "histogram",
                    label = "Histogram",
                ),
                tab(name = "scatterplot",
                    label = "Scatterplot"
                ),
                tab(name = "boxplot",
                    label = "Violin/boxplot"
                ),
            ],
        ),
        tabpanels(
            :tab_selected_plot,
            animated = true,
            var"transition-prev" = "scale",
            var"transition-next" = "scale",
            [
                tabpanel(name = "histogram", uiplothist()),
                tabpanel(name = "scatterplot", uiplotscat()),
                tabpanel(name = "boxplot", uiplotbox()),
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
            class = "bg-green text-white shadow-2",
            activecolorbg = "red",
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
                tabpanel(name = "analyse_and_plot", uiplot()),
                tabpanel(name = "upload_and_validate", [p("Upload/Validate Tab")]),
            ],
        ),
    ]
end

@page("/", ui)
end
