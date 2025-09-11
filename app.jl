module GenomicBreedingApp

using StatsBase, MultivariateStats, DataFrames, Tables, CSV, StippleDownloads
using PlotlyBase, ColorSchemes
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
    
    idx_col_start_numeric_pheno_tables = 18

#####################################################################################################################
# Base tables
    df_analyses = string.(sort(querytable("analyses", fields=["name", "description"])))
    df_entries = string.(sort(querytable("entries", fields=["name", "species", "ploidy", "crop_duration", "description", "individual_or_pool", "population", "maternal_family", "paternal_family", "cultivar"])))
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
    # Ploidies
    ploidies_list = sort(unique(df_entries.ploidy))
    @in ploidies_filter_text = ""             # Input from the text field
    @in ploidies_selected_options::Union{Nothing, Vector{String}} = nothing
    @in ploidies_filtered_options = ploidies_list   # Output/state: starts with all options
    @onchange ploidies_filter_text begin
        search_term = lowercase(ploidies_filter_text)
        if isempty(search_term)
            ploidies_filtered_options = ploidies_list
        else
            ploidies_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), ploidies_list)
        end
    end
    # Crop duration
    crop_durations_list = sort(unique(df_entries.crop_duration))
    @in crop_durations_filter_text = ""             # Input from the text field
    @in crop_durations_selected_options::Union{Nothing, Vector{String}} = nothing
    @in crop_durations_filtered_options = crop_durations_list   # Output/state: starts with all options
    @onchange crop_durations_filter_text begin
        search_term = lowercase(crop_durations_filter_text)
        if isempty(search_term)
            crop_durations_filtered_options = crop_durations_list
        else
            crop_durations_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), crop_durations_list)
        end
    end
    # Individuals or pools
    individuals_or_pools_list = sort(unique(df_entries.individual_or_pool))
    @in individuals_or_pools_filter_text = ""             # Input from the text field
    @in individuals_or_pools_selected_options::Union{Nothing, Vector{String}} = nothing
    @in individuals_or_pools_filtered_options = individuals_or_pools_list   # Output/state: starts with all options
    @onchange individuals_or_pools_filter_text begin
        search_term = lowercase(individuals_or_pools_filter_text)
        if isempty(search_term)
            individuals_or_pools_filtered_options = individuals_or_pools_list
        else
            individuals_or_pools_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), individuals_or_pools_list)
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
    # Maternal families
    maternal_families_list = sort(unique(df_entries.maternal_family))
    @in maternal_families_filter_text = ""             # Input from the text field
    @in maternal_families_selected_options::Union{Nothing, Vector{String}} = nothing
    @in maternal_families_filtered_options = maternal_families_list   # Output/state: starts with all options
    @onchange maternal_families_filter_text begin
        search_term = lowercase(maternal_families_filter_text)
        if isempty(search_term)
            maternal_families_filtered_options = maternal_families_list
        else
            maternal_families_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), maternal_families_list)
        end
    end
    # Paternal families
    paternal_families_list = sort(unique(df_entries.paternal_family))
    @in paternal_families_filter_text = ""             # Input from the text field
    @in paternal_families_selected_options::Union{Nothing, Vector{String}} = nothing
    @in paternal_families_filtered_options = paternal_families_list   # Output/state: starts with all options
    @onchange paternal_families_filter_text begin
        search_term = lowercase(paternal_families_filter_text)
        if isempty(search_term)
            paternal_families_filtered_options = paternal_families_list
        else
            paternal_families_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), paternal_families_list)
        end
    end
    # Cultivars
    cultivars_list = sort(unique(df_entries.cultivar))
    @in cultivars_filter_text = ""             # Input from the text field
    @in cultivars_selected_options::Union{Nothing, Vector{String}} = nothing
    @in cultivars_filtered_options = cultivars_list   # Output/state: starts with all options
    @onchange cultivars_filter_text begin
        search_term = lowercase(cultivars_filter_text)
        if isempty(search_term)
            cultivars_filtered_options = cultivars_list
        else
            cultivars_filtered_options = filter(opt -> occursin(search_term, lowercase(opt)), cultivars_list)
        end
    end
    # Entries
    entries_list = sort(unique(df_entries.name))
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

     # Clear all filters
    @in query_entries_clear_all_filters = false
    @onbutton query_entries_clear_all_filters begin
        traits_selected_options = nothing
        species_selected_options = nothing
        ploidies_selected_options = nothing
        crop_durations_selected_options = nothing
        individuals_or_pools_selected_options = nothing
        populations_selected_options = nothing
        maternal_families_selected_options = nothing
        paternal_families_selected_options = nothing
        cultivars_selected_options = nothing
        entries_selected_options = nothing
        years_selected_options = nothing
        seasons_selected_options = nothing
        harvests_selected_options = nothing
        sites_selected_options = nothing
        replications_selected_options = nothing
        blocks_selected_options = nothing
        rows_selected_options = nothing
        cols_selected_options = nothing
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
            ploidies::Vector{Union{String, Missing}} = isnothing(ploidies_selected_options) ? [x == "missing" ? missing : x for x in ploidies_list] : [x == "missing" ? missing : x for x in ploidies_selected_options]
            crop_durations::Vector{Union{String, Missing}} = isnothing(crop_durations_selected_options) ? [x == "missing" ? missing : x for x in crop_durations_list] : [x == "missing" ? missing : x for x in crop_durations_selected_options]
            individuals_or_pools::Vector{Union{String, Missing}} = isnothing(individuals_or_pools_selected_options) ? [x == "missing" ? missing : x for x in individuals_or_pools_list] : [x == "missing" ? missing : x for x in individuals_or_pools_selected_options]
            populations::Vector{Union{String, Missing}} = isnothing(populations_selected_options) ? [x == "missing" ? missing : x for x in populations_list] : [x == "missing" ? missing : x for x in populations_selected_options]
            maternal_families::Vector{Union{String, Missing}} = isnothing(maternal_families_selected_options) ? [x == "missing" ? missing : x for x in maternal_families_list] : [x == "missing" ? missing : x for x in maternal_families_selected_options]
            paternal_families::Vector{Union{String, Missing}} = isnothing(paternal_families_selected_options) ? [x == "missing" ? missing : x for x in paternal_families_list] : [x == "missing" ? missing : x for x in paternal_families_selected_options]
            cultivars::Vector{Union{String, Missing}} = isnothing(cultivars_selected_options) ? [x == "missing" ? missing : x for x in cultivars_list] : [x == "missing" ? missing : x for x in cultivars_selected_options]
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
                ploidies = ploidies,
                crop_durations = crop_durations,
                individuals_or_pools = individuals_or_pools,
                populations = populations,
                maternal_families = maternal_families,
                paternal_families = paternal_families,
                cultivars = cultivars,
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
    @in query_entries_select_all_traits = false
    @onbutton query_entries_select_all_traits begin
        traits_selected_options = traits_list
    end
    @in query_entries_select_all_entries = false
    @onbutton query_entries_select_all_entries begin
        entries_selected_options = entries_list
    end
    @in query_entries_select_all_populations = false
    @onbutton query_entries_select_all_populations begin
        populations_selected_options = populations_list
    end
    @in query_entries_select_all_individuals_or_pools = false
    @onbutton query_entries_select_all_individuals_or_pools begin
        individuals_or_pools_selected_options = individuals_or_pools_list
    end
    @in query_entries_select_all_species = false
    @onbutton query_entries_select_all_species begin
        species_selected_options = species_list
    end
    @in query_entries_select_all_ploidies = false
    @onbutton query_entries_select_all_ploidies begin
        ploidies_selected_options = ploidies_list
    end
    @in query_entries_select_all_crop_durations = false
    @onbutton query_entries_select_all_crop_durations begin
        crop_durations_selected_options = crop_durations_list
    end
    @in query_entries_select_all_maternal_families = false
    @onbutton query_entries_select_all_maternal_families begin
        maternal_families_selected_options = maternal_families_list
    end
    @in query_entries_select_all_paternal_families = false
    @onbutton query_entries_select_all_paternal_families begin
        paternal_families_selected_options = paternal_families_list
    end
    @in query_entries_select_all_cultivars = false
    @onbutton query_entries_select_all_cultivars begin
        cultivars_selected_options = cultivars_list
    end
    @in query_entries_select_all_years = false
    @onbutton query_entries_select_all_years begin
        years_selected_options = years_list
    end
    @in query_entries_select_all_seasons = false
    @onbutton query_entries_select_all_seasons begin
        seasons_selected_options = seasons_list
    end
    @in query_entries_select_all_harvests = false
    @onbutton query_entries_select_all_harvests begin
        harvests_selected_options = harvests_list
    end
    @in query_entries_select_all_sites = false
    @onbutton query_entries_select_all_sites begin
        sites_selected_options = sites_list
    end
    @in query_entries_select_all_replications = false
    @onbutton query_entries_select_all_replications begin
        replications_selected_options = replications_list
    end
    @in query_entries_select_all_blocks = false
    @onbutton query_entries_select_all_blocks begin
        blocks_selected_options = blocks_list
    end
    @in query_entries_select_all_rows = false
    @onbutton query_entries_select_all_rows begin
        rows_selected_options = rows_list
    end
    @in query_entries_select_all_cols = false
    @onbutton query_entries_select_all_cols begin
        cols_selected_options = cols_list
    end
    
    @event download_entries begin
        download_binary(__model__, df_to_io(table_query_entries.data), "entries_data.txt", )
    end
######################################################################################################################
# Plots

    # Initialize three DataFrames (one for each plot type) with some initial data
    df = [
        queryanalyses(analyses=[querytable("analyses").name[1]], verbose=true),
        queryanalyses(analyses=[querytable("analyses").name[1]], verbose=true), 
        queryanalyses(analyses=[querytable("analyses").name[1]], verbose=true), 
        queryanalyses(analyses=[querytable("analyses").name[1]], verbose=true),
    ]

    #####################################################
    # Histogram plotting functionality
    #####################################################
    
        # Define reactive inputs for histogram plot
        @in selected_table_to_plot_hist::Vector{String} = ["analyses"] # Which table to plot from
        @out choices_tables_to_plot_hist::Vector{String} = ["analyses", "trials/entries"] # Available table choices
        @in selected_plot_traits_hist::Vector{String} = [] # Which traits to plot histograms for
        @out choices_plot_traits_hist::Vector{String} = names(df[1])[idx_col_start_numeric_pheno_tables:end] # Available trait choices (columns idx_col_start_numeric_pheno_tables+ contain trait data)

        @in selected_agg_func_per_season_hist::Vector{String} = ["missing"]
        @out choices_agg_func_per_season_hist::Vector{String} = ["sum", "mean", "missing"]

        # Create initial histogram plots for all traits
        plots_vector_hist = []
        for t in names(df[1])[idx_col_start_numeric_pheno_tables:end]
            push!(plots_vector_hist, PlotlyBase.histogram(x=df[1][!, t]))
        end
        plots_layout_hist = PlotlyBase.Layout(barmode="overlay")
        @out plotdata_hist = plots_vector_hist
        @out plotlayout_hist = plots_layout_hist


        function reactivehistdata(
            df::Vector{DataFrame};
            selected_table_to_plot_hist::Vector{String},
            table_query_analyses::DataTable, 
            table_query_entries::DataTable,
        )::Dict{String, Union{DataFrame, Vector{String}}}
            selected_plot_traits_hist::Vector{String} = []
            choices_plot_traits_hist::Vector{String} = []
            # Get data from selected table
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
            # Update trait choices
            choices_plot_traits_hist = if ncol(df[1]) == 0
                ["missing"]
            else
                names(df[1])[idx_col_start_numeric_pheno_tables:end]
            end
            # Output
            Dict(
                "df_1" => df[1],
                "selected_plot_traits_hist" => selected_plot_traits_hist,
                "choices_plot_traits_hist" => choices_plot_traits_hist,
            )
        end

        # When user changes selected table, update available trait choices
        @onchange selected_table_to_plot_hist begin
            res = reactivehistdata(
                df,
                selected_table_to_plot_hist=selected_table_to_plot_hist,
                table_query_analyses=table_query_analyses, 
                table_query_entries=table_query_entries,
            )
            df[1] = res["df_1"]
            selected_plot_traits_hist = res["selected_plot_traits_hist"]
            choices_plot_traits_hist = res["choices_plot_traits_hist"]
        end

        function reactivehistplot(df::Vector{DataFrame}; selected_plot_traits_hist::Vector{String}, selected_agg_func_per_season_hist::Vector{String})
            println("Plotting histogram")
            plots_vector_hist = []
            for t in selected_plot_traits_hist
                try 
                    df[1][!, t]
                catch
                    continue
                end
                # Define the input data frame aggregate or not?
                df_agg = if selected_agg_func_per_season_hist[1] == "sum"
                    combine(
                        groupby(df[1], [:year, :season, :site, :replication, :block, :row, :col]), 
                        [
                            t => (x -> sum(x[.!ismissing.(x) .&& .!isnan.(x) .&& .!isinf.(x)])) => t, 
                            t => (x -> "misssing") => "harvest"
                        ]
                    )
                elseif selected_agg_func_per_season_hist[1] == "mean"
                    combine(
                        groupby(df[1], [:year, :season, :site, :replication, :block, :row, :col]), 
                        [
                            t => (x -> mean(x[.!ismissing.(x) .&& .!isnan.(x) .&& .!isinf.(x)])) => t, 
                            t => (x -> "misssing") => "harvest"
                        ]
                    )
                else
                    df[1]
                end
                # Filter out missing/invalid values
                x = filter(x -> !isnothing(x) && !ismissing(x) && !isinf(x), df_agg[!, t])
                if length(x) < 1
                    continue
                end
                push!(plots_vector_hist, PlotlyBase.histogram(x=x, opacity=0.5, name=t))
            end
            plots_layout_hist = PlotlyBase.Layout(barmode="overlay")
            # Update plot
            Dict(
                "plotdata_hist" => plots_vector_hist,
                "plotlayout_hist" => plots_layout_hist,
            )
        end

        # When plot button clicked, create histograms for selected traits
        @in plot_table_hist = false
        @onbutton plot_table_hist begin
            p = reactivehistplot(
                df,
                selected_plot_traits_hist=selected_plot_traits_hist,
                selected_agg_func_per_season_hist=selected_agg_func_per_season_hist
            )
            plotdata_hist = p["plotdata_hist"]
            plotlayout_hist = p["plotlayout_hist"]
        end

    #####################################################
    # Scatter plot functionality 
    #####################################################

        # Define reactive inputs for scatter plot
        @in selected_table_to_plot_scat::Vector{String} = ["analyses"]
        @out choices_tables_to_plot_scat::Vector{String} = ["analyses", "trials/entries"]
        @in selected_plot_traits_scat_x::Vector{String} = [] # X-axis trait
        @out choices_plot_traits_scat_x::Vector{String} = names(df[2])[idx_col_start_numeric_pheno_tables:end]
        @in selected_plot_traits_scat_y::Vector{String} = [] # Y-axis trait  
        @out choices_plot_traits_scat_y::Vector{String} = names(df[2])[idx_col_start_numeric_pheno_tables:end]
        @in selected_plot_traits_scat_z::Vector{String} = ["name"]
        @out choices_plot_traits_scat_z::Vector{String} = names(df[2])

        @in selected_plot_colour_scheme_scat = :seaborn_colorblind
        @out choices_plot_colour_scheme_scat = [:seaborn_colorblind, :tol_bright, :tol_light, :tol_muted, :okabe_ito, :mk_15]
        @in n_bins_plot_scat = 5

        # Filters


        # Aggregators
        @out choices_agg_func_per_season_scat::Vector{String} = ["sum", "mean", "missing"]
        @in selected_agg_func_per_season_scat_x::Vector{String} = ["missing"]
        @in selected_agg_func_per_season_scat_y::Vector{String} = ["missing"]
        
        # Create initial scatter plot
        plots_vector_scat = []
        x = df[2][:, idx_col_start_numeric_pheno_tables]
        y = df[2][:, end]
        # Filter valid points
        idx = findall(.!ismissing.(x) .&& .!ismissing.(y) .&& .!isnan.(x) .&& .!isnan.(y) .&& .!isinf.(x) .&& .!isinf.(y))
        x = x[idx]
        y = y[idx]
        plots_vector_scat = [PlotlyBase.scatter(x=x, y=y, mode="markers")]
        plots_layout_scat = PlotlyBase.Layout()
        @out plotdata_scat = plots_vector_scat
        @out plotlayout_scat = plots_layout_scat

        # When table selection changes, update trait choices
        @onchange selected_table_to_plot_scat begin
            selected_plot_traits_scat_x = []
            choices_plot_traits_scat_x = []
            selected_plot_traits_scat_y = []
            choices_plot_traits_scat_y = []
            selected_plot_traits_scat_z = []
            choices_plot_traits_scat_z = []
            selected_agg_func_per_season_scat_x = ["missing"]
            selected_agg_func_per_season_scat_y = ["missing"]
            df[2] = if selected_table_to_plot_scat == ["analyses"]
                if nrow(table_query_analyses.data) == 0
                    println("No data to plot")
                    return DataFrame()
                else
                    if nrow(table_query_analyses.data) < 100_000
                        table_query_analyses.data
                    else
                        table_query_analyses.data
                    end
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
                names(df[2])[idx_col_start_numeric_pheno_tables:end]
            end
            choices_plot_traits_scat_y = if ncol(df[2]) == 0
                ["missing"]
            else
                names(df[2])[idx_col_start_numeric_pheno_tables:end]
            end
            choices_plot_traits_scat_z = names(df[2])
        end


        # TODO: add option to aggregate the y-values per season, year, sites, etc..

        # TODO: (2/3) parameterise, add tests and docs + move to a separate file
 

        function reactivescatter(
            df::Vector{DataFrame};
            selected_plot_traits_scat_x::Vector{String},
            selected_plot_traits_scat_y::Vector{String},
            selected_plot_traits_scat_z::Vector{String},
            selected_agg_func_per_season_scat_x::Vector{String},
            selected_agg_func_per_season_scat_y::Vector{String},
            n_bins_plot_scat::Int64,
            selected_plot_colour_scheme_scat::Symbol
        )::Dict{String, Any}
            println("Plotting scatterplot")
            # Aggregate x
            t = selected_plot_traits_scat_x[1]
            df_agg_x, x_agg = if selected_agg_func_per_season_scat_x[1] == "sum"
                x_agg = string(t, "_sum")
                df_agg = combine(
                    groupby(df[2], [:year, :season, :site, :replication, :block, :row, :col, :species, :ploidy, :crop_duration, :individual_or_pool, :maternal_family, :paternal_family, :cultivar, :name, :population]), 
                    [
                        t => (x -> "misssing") => "harvest", 
                        t => (x -> sum(x[.!ismissing.(x) .&& .!isnan.(x) .&& .!isinf.(x)])) => x_agg, 
                    ]
                )
                (df_agg, x_agg)
            elseif selected_agg_func_per_season_scat_x[1] == "mean"
                x_agg = string(t, "_mean")
                df_agg = combine(
                    groupby(df[2], [:year, :season, :site, :replication, :block, :row, :col, :species, :ploidy, :crop_duration, :individual_or_pool, :maternal_family, :paternal_family, :cultivar, :name, :population]), 
                    [
                        t => (x -> "misssing") => "harvest", 
                        t => (x -> mean(x[.!ismissing.(x) .&& .!isnan.(x) .&& .!isinf.(x)])) => x_agg, 
                    ]
                )
                (df_agg, x_agg)
            else
                x_agg = string(t, "_no_agg")
                df_agg = df[2][:, [:year, :season, :harvest, :site, :replication, :block, :row, :col, :species, :ploidy, :crop_duration, :individual_or_pool, :maternal_family, :paternal_family, :cultivar, :name, :population, Symbol(t)]]
                rename!(df_agg, t => x_agg)
                (df_agg, x_agg)
            end
            # Aggregate y
            t = selected_plot_traits_scat_y[1]
            df_agg_y, y_agg = if (selected_agg_func_per_season_scat_y[1] == "sum") || ((selected_agg_func_per_season_scat_x[1] == "sum") && (selected_agg_func_per_season_scat_y[1] == "missing"))
                y_agg = string(t, "_sum")
                df_agg = combine(
                    groupby(df[2], [:year, :season, :site, :replication, :block, :row, :col, :species, :ploidy, :crop_duration, :individual_or_pool, :maternal_family, :paternal_family, :cultivar, :name, :population]), 
                    [
                        t => (x -> "misssing") => "harvest", 
                        t => (x -> sum(x[.!ismissing.(x) .&& .!isnan.(x) .&& .!isinf.(x)])) => y_agg, 
                    ]
                )
                (df_agg, y_agg)
            elseif (selected_agg_func_per_season_scat_y[1] == "mean") || ((selected_agg_func_per_season_scat_x[1] == "mean") && (selected_agg_func_per_season_scat_y[1] == "missing"))
                y_agg = string(t, "_mean")
                df_agg = combine(
                    groupby(df[2], [:year, :season, :site, :replication, :block, :row, :col, :species, :ploidy, :crop_duration, :individual_or_pool, :maternal_family, :paternal_family, :cultivar, :name, :population]), 
                    [
                        t => (x -> "misssing") => "harvest", 
                        t => (x -> mean(x[.!ismissing.(x) .&& .!isnan.(x) .&& .!isinf.(x)])) => y_agg, 
                    ]
                )
                (df_agg, y_agg)
            else
                y_agg = string(t, "_no_agg")
                df_agg = df[2][:, [:year, :season, :harvest, :site, :replication, :block, :row, :col, :species, :ploidy, :crop_duration, :individual_or_pool, :maternal_family, :paternal_family, :cultivar, :name, :population, Symbol(t)]]
                rename!(df_agg, t => y_agg)
                (df_agg, y_agg)
            end
            # Aggregate z
            t = selected_plot_traits_scat_z[1]
            df_agg_z, z_agg = if t ∈ names(df_agg_x)[1:(end-1)]
                df_agg = df_agg_x[:, [:year, :season, :harvest, :site, :replication, :block, :row, :col, :species, :ploidy, :crop_duration, :individual_or_pool, :maternal_family, :paternal_family, :cultivar, :name, :population]]
                z_agg = t
                (df_agg, z_agg)
            elseif (selected_agg_func_per_season_scat_x[1] != "missing") || (selected_agg_func_per_season_scat_y[1] != "missing")
                z_agg = string(t, "_mean")
                df_agg = combine(
                    groupby(df[2], [:year, :season, :site, :replication, :block, :row, :col, :species, :ploidy, :crop_duration, :individual_or_pool, :maternal_family, :paternal_family, :cultivar, :name, :population]), 
                    [
                        t => (x -> "misssing") => "harvest", 
                        t => (x -> mean(x[.!ismissing.(x) .&& .!isnan.(x) .&& .!isinf.(x)])) => z_agg, 
                    ]
                )
                (df_agg, z_agg)
            else
                z_agg = string(t, "_no_agg")
                df_agg = df[2][:, [:year, :season, :harvest, :site, :replication, :block, :row, :col, :species, :ploidy, :crop_duration, :individual_or_pool, :maternal_family, :paternal_family, :cultivar, :name, :population, Symbol(t)]]
                rename!(df_agg, t => z_agg)
                (df_agg, z_agg)
            end
            @show "!!!!Z!!!!"
            @show t
            @show z_agg
            @show nrow(df_agg_z)
            @show "!!!!!!!!!!!!!"            

            x_agg, y_agg, z_agg = if x_agg == y_agg == z_agg
                rename!(df_agg_x, x_agg => x_agg * "_1")
                rename!(df_agg_y, y_agg => y_agg * "_2")
                rename!(df_agg_z, z_agg => z_agg * "_3")
                (x_agg * "_1", y_agg * "_2", z_agg * "_3")
            elseif x_agg == y_agg != z_agg
                rename!(df_agg_x, x_agg => x_agg * "_1")
                rename!(df_agg_y, y_agg => y_agg * "_2")
                (x_agg * "_1", y_agg * "_2", z_agg)
            elseif x_agg != y_agg == z_agg
                rename!(df_agg_y, y_agg => y_agg * "_1")
                rename!(df_agg_z, z_agg => z_agg * "_2")
                (x_agg, y_agg * "_1", z_agg * "_2")
            elseif x_agg == z_agg != y_agg
                rename!(df_agg_x, x_agg => x_agg * "_1")
                rename!(df_agg_z, z_agg => z_agg * "_2")
                (x_agg * "_1", y_agg, z_agg * "_2")
            else
                (x_agg, y_agg, z_agg)
            end
            # Convert missing to "missing"
            println("Set missing in df_agg_x and df_agg_y:")
            @show nrow(df_agg_x)
            @show nrow(df_agg_y)
            @show nrow(df_agg_z)
            for i in 1:nrow(df_agg_x)
                for j in 1:(ncol(df_agg_x)-1)
                    if ismissing(df_agg_x[i, j])
                        df_agg_x[i, j] = "missing"
                    end
                    if ismissing(df_agg_y[i, j])
                        df_agg_y[i, j] = "missing"
                    end
                    if ismissing(df_agg_z[i, j])
                        df_agg_z[i, j] = "missing"
                    end
                end
            end
            # Merge
            println("Leftjoining")
            df_agg = leftjoin(
                df_agg_x,
                leftjoin(
                    df_agg_y, 
                    df_agg_z, 
                    on=[:year, :season, :harvest, :site, :replication, :block, :row, :col, :species, :ploidy, :crop_duration, :individual_or_pool, :maternal_family, :paternal_family, :cultivar, :name, :population]
                ),
                on=[:year, :season, :harvest, :site, :replication, :block, :row, :col, :species, :ploidy, :crop_duration, :individual_or_pool, :maternal_family, :paternal_family, :cultivar, :name, :population]
            );
            @show nrow(df_agg)

            # Extract x, y, and z values
            x = df_agg[!, x_agg]
            y = df_agg[!, y_agg]
            z = df_agg[!, z_agg]
            # Set up color scheme for points
            z = begin
                z_new = repeat(["missing"], length(z))
                idx = findall(.!ismissing.(z))
                if (length(idx) > 0) && !isa(z[idx[1]], String) 
                    idx = findall(.!ismissing.(z) .&& .!isnan.(z) .&& .!isinf.(z))
                    n = if n_bins_plot_scat > length(z)
                        length(z)
                    else
                        n_bins_plot_scat
                    end
                    unique_z = percentile(
                        filter(z -> !ismissing(z) && !isnan(z) && !isinf(z), z), 
                        100 .* collect(0:1/n:1)
                    )
                    m1 = length(split(string(maximum(round.(unique_z))), ".")[1])
                    m2 = 4
                    for (j, z_level) in enumerate(unique_z)
                        if j == 1
                            continue
                        end
                        idx_sub = if j == 2
                            # include the minimum
                            filter(i -> (z[i] >= unique_z[j-1]) && (z[i] <= unique_z[j]), idx)
                        else
                            filter(i -> (z[i] > unique_z[j-1]) && (z[i] <= unique_z[j]), idx)
                        end
                        ini = begin
                            ini = string((round(unique_z[j-1], digits=4)))
                            join([lpad(split(ini, ".")[1], m1, "0"), rpad(split(ini, ".")[2], m2, "0")], ".")
                        end
                        fin = begin
                            fin = string((round(unique_z[j], digits=4)))
                            join([lpad(split(fin, ".")[1], m1, "0"), rpad(split(fin, ".")[2], m2, "0")], ".")
                        end
                        z_new[idx_sub] .= string(ini, " - ", fin)
                    end
                else
                    z_new[idx] = z[idx]
                end
                z_new
            end
            # Map colours to points
            unique_z = sort(unique(z))
            colours_per_unique_z = try
                colorschemes[selected_plot_colour_scheme_scat][1:length(unique_z)]
            catch
                repeat(
                    colorschemes[selected_plot_colour_scheme_scat][1:end], 
                    outer=Int(ceil(length(unique_z)/length(colorschemes[selected_plot_colour_scheme_scat])))
                )[1:length(unique_z)]
            end
            # colours = [colours_per_unique_z[unique_z .== zi][1] for zi in z]
            # Create hover text for each point
            hovertext = [
                join(
                    filter(x -> !isnothing(x) && split(x, ": ")[end] != "missing", [
                        # Trials and phenomes
                        "name" ∈ names(df_agg) ? string("name: ", df_agg.name[i]) : nothing,
                        "population" ∈ names(df_agg) ? string("population: ", df_agg.population[i]) : nothing,
                        "year" ∈ names(df_agg) ? string("year: ", df_agg.year[i]) : nothing,
                        "season" ∈ names(df_agg) ? string("season: ", df_agg.season[i]) : nothing,
                        "site" ∈ names(df_agg) ? string("site: ", df_agg.site[i]) : nothing,
                        "harvest" ∈ names(df_agg) ? string("harvest: ", df_agg.harvest[i]) : nothing,
                        "replication" ∈ names(df_agg) ? string("replication: ", df_agg.replication[i]) : nothing,
                        "block" ∈ names(df_agg) ? string("block: ", df_agg.block[i]) : nothing,
                        "row" ∈ names(df_agg) ? string("row: ", df_agg.row[i]) : nothing,
                        "column" ∈ names(df_agg) ? string("column: ", df_agg.column[i]) : nothing,
                        # CVs
                        "fold" ∈ names(df_agg) ? string("fold: ", df_agg.fold[i]) : nothing,
                        string(selected_plot_traits_scat_x[1], ": ", round(x[i], digits=4)),
                        string(selected_plot_traits_scat_y[1], ": ", round(y[i], digits=4))
                    ]), "<br>"
                ) for i in 1:length(x)
            ]

            # Create scatter plot for each group
            plots_vector_scat = []
            for (j, g) in enumerate(unique_z)
                group_indices = filter(i -> z[i] == g, idx)
                push!(plots_vector_scat, 
                    scatter(
                        x=x[group_indices], 
                        y=y[group_indices], 
                        mode="markers", 
                        opacity=0.75,
                        hoverinfo="text", 
                        hovertext=hovertext[group_indices],
                        # marker=attr(color=colours[group_indices]), 
                        name=g
                    )
                )
            end

            # Set plot layout
            plots_layout_scat = PlotlyBase.Layout(
                title=string("Scatterplot of ", selected_plot_traits_scat_x[1], " vs ", selected_plot_traits_scat_y[1]),
                xaxis_title=selected_plot_traits_scat_x[1],
                yaxis_title=selected_plot_traits_scat_y[1],
                showlegend=true,
                legend=attr(title=attr(text=selected_plot_traits_scat_z[1])),
                colorway=colours_per_unique_z,
            )
            # Update plot
            Dict(
                "plotdata_scat" => plots_vector_scat,
                "plotlayout_scat" => plots_layout_scat,
            )
        end


        # When plot button clicked, create scatter plot
        @in plot_table_scat = false
        @onbutton plot_table_scat begin
            p = reactivescatter(
                df,
                selected_plot_traits_scat_x=selected_plot_traits_scat_x,
                selected_plot_traits_scat_y=selected_plot_traits_scat_y,
                selected_plot_traits_scat_z=selected_plot_traits_scat_z,
                selected_agg_func_per_season_scat_x=selected_agg_func_per_season_scat_x,
                selected_agg_func_per_season_scat_y=selected_agg_func_per_season_scat_y,
                n_bins_plot_scat=n_bins_plot_scat,
                selected_plot_colour_scheme_scat=selected_plot_colour_scheme_scat,
            )
            plotdata_scat = p["plotdata_scat"]
            plotlayout_scat = p["plotlayout_scat"]
        end

    #####################################################
    # PCA biplot functionality 
    #####################################################

        # Define reactive inputs for PCA biplot
        @in selected_table_to_plot_pca::Vector{String} = ["analyses"]
        @out choices_tables_to_plot_pca::Vector{String} = ["analyses", "trials/entries"]

        # PCA
        IDX = findall((sum(.!ismissing.(Matrix(df[3][:, idx_col_start_numeric_pheno_tables:end])), dims=2) .== size)[:,1] .== 0)
        A = Matrix(df[3][IDX, idx_col_start_numeric_pheno_tables:end])
        A = (A .- mean(A, dims = 1)) ./ std(A, dims = 1)
        v = StatsBase.var(A, dims = 1)[1, :]
        idx_cols = findall((abs.(v .- 1) .< 0.00001) .&& .!isnan.(v) .&& .!ismissing.(v) .&& .!isinf.(v))
        A = A[:, idx_cols]
        M = MultivariateStats.fit(MultivariateStats.PCA, A)
        for j in 1:size(M.proj, 2)
            df[3][!, "PC$j"] = M.proj[:, j]
        end

        @in selected_plot_traits_pca_x::Vector{String} = ["PC1"] # X-axis trait
        @out choices_plot_traits_pca_x::Vector{String} = ["PC$j" for j in 1:size(M.proj, 2)]
        @in selected_plot_traits_pca_y::Vector{String} = ["PC2"] # Y-axis trait  
        @out choices_plot_traits_pca_y::Vector{String} = ["PC$j" for j in 1:size(M.proj, 2)]


        @in selected_plot_traits_pca_z::Vector{String} = ["name"]
        @out choices_plot_traits_pca_z::Vector{String} = names(df[3])

        @in selected_plot_colour_scheme_pca = :seaborn_colorblind
        @out choices_plot_colour_scheme_pca = [:seaborn_colorblind, :tol_bright, :tol_light, :tol_muted, :okabe_ito, :mk_15]

        
        # Create initial PCA biplot
        plots_vector_pca = []
        x = df[3].PC1
        y = df[3].PC2
        idx = findall(.!ismissing.(x) .&& .!ismissing.(y) .&& .!isnan.(x) .&& .!isnan.(y) .&& .!isinf.(x) .&& .!isinf.(y))
        x = x[idx]
        y = y[idx]
        plots_vector_pca = [PlotlyBase.scatter(x=x, y=y, mode="markers")]
        plots_layout_pca = PlotlyBase.Layout()
        @out plotdata_pca = plots_vector_pca
        @out plotlayout_pca = plots_layout_pca


        # When table selection changes, update trait choices
        @onchange selected_table_to_plot_pca begin
            choices_plot_traits_pca_x = []
            choices_plot_traits_pca_y = []
            selected_plot_traits_pca_z = []
            choices_plot_traits_pca_z = []
            # selected_agg_func_per_season_pca_x = ["missing"]
            # selected_agg_func_per_season_pca_y = ["missing"]
            df[3] = if selected_table_to_plot_pca == ["analyses"]
                if nrow(table_query_analyses.data) == 0
                    println("No data to plot")
                    return DataFrame()
                else
                    if nrow(table_query_analyses.data) < 100_000
                        table_query_analyses.data
                    else
                        table_query_analyses.data
                    end
                end
            elseif selected_table_to_plot_pca == ["trials/entries"]
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
            # PCA
            IDX = findall((sum(.!ismissing.(Matrix(df[3][:, idx_col_start_numeric_pheno_tables:end])), dims=2) .== size)[:,1] .== 0)
            A = Matrix(df[3][IDX, idx_col_start_numeric_pheno_tables:end])
            A = (A .- mean(A, dims = 1)) ./ std(A, dims = 1)
            v = StatsBase.var(A, dims = 1)[1, :]
            idx_cols = findall((abs.(v .- 1) .< 0.00001) .&& .!isnan.(v) .&& .!ismissing.(v) .&& .!isinf.(v))
            A = A[:, idx_cols]
            M = MultivariateStats.fit(MultivariateStats.PCA, A)
            for j in 1:size(M.proj, 2)
                df[3][!, "PC$j"] = M.proj[:, j]
            end
            choices_plot_traits_pca_x = ["PC$j" for j in 1:size(M.proj, 2)]
            choices_plot_traits_pca_y = ["PC$j" for j in 1:size(M.proj, 2)]
        end


        function reactivepcbiplot(
            df::Vector{DataFrame};
            selected_plot_traits_pca_x::Vector{String} = ["PC1"],
            selected_plot_traits_pca_y::Vector{String} = ["PC2"],
            selected_plot_traits_pca_z::Vector{String},
            selected_plot_colour_scheme_pca::Symbol
        )::Dict{String, Any}
            println("Plotting scatterplot")
            
            # Extract x, y, and z values
            x = df[3][!, selected_plot_traits_pca_x[1]]
            y = df[3][!, selected_plot_traits_pca_y[1]]
            z = df[3][!, selected_plot_traits_pca_z[1]]
            # Set up color scheme for points
            z = begin
                z_new = repeat(["missing"], length(z))
                idx = findall(.!ismissing.(z))
                if (length(idx) > 0) && !isa(z[idx[1]], String) 
                    idx = findall(.!ismissing.(z) .&& .!isnan.(z) .&& .!isinf.(z))
                    n = if n_bins_plot_pca > length(z)
                        length(z)
                    else
                        n_bins_plot_pca
                    end
                    unique_z = percentile(
                        filter(z -> !ismissing(z) && !isnan(z) && !isinf(z), z), 
                        100 .* collect(0:1/n:1)
                    )
                    m1 = length(split(string(maximum(round.(unique_z))), ".")[1])
                    m2 = 4
                    for (j, z_level) in enumerate(unique_z)
                        if j == 1
                            continue
                        end
                        idx_sub = if j == 2
                            # include the minimum
                            filter(i -> (z[i] >= unique_z[j-1]) && (z[i] <= unique_z[j]), idx)
                        else
                            filter(i -> (z[i] > unique_z[j-1]) && (z[i] <= unique_z[j]), idx)
                        end
                        ini = begin
                            ini = string((round(unique_z[j-1], digits=4)))
                            join([lpad(split(ini, ".")[1], m1, "0"), rpad(split(ini, ".")[2], m2, "0")], ".")
                        end
                        fin = begin
                            fin = string((round(unique_z[j], digits=4)))
                            join([lpad(split(fin, ".")[1], m1, "0"), rpad(split(fin, ".")[2], m2, "0")], ".")
                        end
                        z_new[idx_sub] .= string(ini, " - ", fin)
                    end
                else
                    z_new[idx] = z[idx]
                end
                z_new
            end
            # Map colours to points
            unique_z = sort(unique(z))
            colours_per_unique_z = try
                colorschemes[selected_plot_colour_scheme_pca][1:length(unique_z)]
            catch
                repeat(
                    colorschemes[selected_plot_colour_scheme_pca][1:end], 
                    outer=Int(ceil(length(unique_z)/length(colorschemes[selected_plot_colour_scheme_pca])))
                )[1:length(unique_z)]
            end
            # colours = [colours_per_unique_z[unique_z .== zi][1] for zi in z]
            # Create hover text for each point
            hovertext = [
                join(
                    filter(x -> !isnothing(x) && split(x, ": ")[end] != "missing", [
                        # Trials and phenomes
                        "name" ∈ names(df[3]) ? string("name: ", df[3].name[IDX[idx]]) : nothing,
                        "population" ∈ names(df[3]) ? string("population: ", df[3].population[IDX[idx]]) : nothing,
                        "year" ∈ names(df[3]) ? string("year: ", df[3].year[IDX[idx]]) : nothing,
                        "season" ∈ names(df[3]) ? string("season: ", df[3].season[IDX[idx]]) : nothing,
                        "site" ∈ names(df[3]) ? string("site: ", df[3].site[IDX[idx]]) : nothing,
                        "harvest" ∈ names(df[3]) ? string("harvest: ", df[3].harvest[IDX[idx]]) : nothing,
                        "replication" ∈ names(df[3]) ? string("replication: ", df[3].replication[IDX[idx]]) : nothing,
                        "block" ∈ names(df[3]) ? string("block: ", df[3].block[IDX[idx]]) : nothing,
                        "row" ∈ names(df[3]) ? string("row: ", df[3].row[IDX[idx]]) : nothing,
                        "col" ∈ names(df[3]) ? string("column: ", df[3].col[IDX[idx]]) : nothing,
                        # CVs
                        "fold" ∈ names(df[3]) ? string("fold: ", df[3].fold[IDX[idx]]) : nothing,
                        string(selected_plot_traits_pca_x[1], ": ", round(x[idx], digits=4)),
                        string(selected_plot_traits_pca_y[1], ": ", round(y[idx], digits=4)),
                        [string(names(df[3])[idx_col_start_numeric_pheno_tables+(j-1)], ": ", round(A[idx, j], digits=4)) for j in 1:size(A,2)]...
                    ]), "<br>"
                ) for idx in 1:length(x)
            ]

            # Create scatter plot for each group
            plots_vector_pca = []
            for (j, g) in enumerate(unique_z)
                group_indices = filter(i -> z[i] == g, idx)
                push!(plots_vector_pca, 
                    scatter(
                        x=x[group_indices], 
                        y=y[group_indices], 
                        mode="markers", 
                        opacity=0.75,
                        hoverinfo="text", 
                        hovertext=hovertext[group_indices],
                        # marker=attr(color=colours[group_indices]), 
                        name=g
                    )
                )
            end

            # Set plot layout
            plots_layout_pca = PlotlyBase.Layout(
                title=string("Scatterplot of ", selected_plot_traits_pca_x[1], " vs ", selected_plot_traits_pca_y[1]),
                xaxis_title=selected_plot_traits_pca_x[1],
                yaxis_title=selected_plot_traits_pca_y[1],
                showlegend=true,
                legend=attr(title=attr(text=selected_plot_traits_pca_z[1])),
                colorway=colours_per_unique_z,
            )
            # Update plot
            Dict(
                "plotdata_pca" => plots_vector_pca,
                "plotlayout_pca" => plots_layout_pca,
            )
        end


        # When plot button clicked, create scatter plot
        @in plot_table_pca = false
        @onbutton plot_table_pca begin
            p = reactivepcbiplot(
                df,
                selected_plot_traits_pca_x=selected_plot_traits_pca_x,
                selected_plot_traits_pca_y=selected_plot_traits_pca_y,
                selected_plot_traits_pca_z=selected_plot_traits_pca_z,
                selected_plot_colour_scheme_pca=selected_plot_colour_scheme_pca,
            )
            plotdata_pca = p["plotdata_pca"]
            plotlayout_pca = p["plotlayout_pca"]
        end

    #####################################################
    # Box plot functionality
    #####################################################

        # Define reactive inputs for box plot
        @in selected_table_to_plot_box = ["analyses"]
        @out choices_tables_to_plot_box = ["analyses", "trials/entries"]
        
        @in selected_plot_traits_box = []
        @out choices_plot_traits_box = names(df[4])[idx_col_start_numeric_pheno_tables:end]

        @in selected_plot_grouping_1_box = []
        @out choices_plot_grouping_1_box = names(df[4])
        @in selected_plot_grouping_2_box = []
        @out choices_plot_grouping_2_box = names(df[4])

        @in n_bins_plot_grouping_1_box = 5
        @in n_bins_plot_grouping_2_box = 5
        @in selected_plot_colour_scheme_box = :seaborn_colorblind
        @out choices_plot_colour_scheme_box = [:seaborn_colorblind, :tol_bright, :tol_light, :tol_muted, :okabe_ito, :mk_15]



        # Create initial box plots
        plots_vector_box = []
        x = df[4][:, "name"]
        y = df[4][:, end]
        # Filter valid points
        idx = findall(.!ismissing.(y) .&& .!isnan.(y) .&& .!isinf.(y))
        x = x[idx]
        y = y[idx]
        plots_vector_box = [PlotlyBase.box(x=x, y=y)]
        plots_layout_box = PlotlyBase.Layout()
        @out plotdata_box = plots_vector_box
        @out plotlayout_box = plots_layout_box

        # When table selection changes, update trait choices
        @onchange selected_table_to_plot_box begin
            selected_plot_traits_box = []
            choices_plot_traits_box = []
            selected_plot_grouping_1_box = []
            choices_plot_grouping_1_box = []
            selected_plot_grouping_2_box = []
            choices_plot_grouping_2_box = []
            df[4] = if selected_table_to_plot_box == ["analyses"]
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
            choices_plot_traits_box = if ncol(df[4]) == 0
                ["missing"]
            else
                names(df[4])[idx_col_start_numeric_pheno_tables:end]
            end
            choices_plot_grouping_1_box = names(df[4])
            choices_plot_grouping_2_box = names(df[4])
        end



        # TODO: add option to aggregate the y-values per season, year, sites, etc..
        
        # TODO: (3/3) parameterise, add tests and docs + move to a separate file
        function reactivebox(
            df, 
            selected_plot_traits_box,
            selected_plot_grouping_1_box,
            selected_plot_grouping_2_box,
            selected_plot_colour_scheme_box,
            n_bins_plot_grouping_1_box,
            n_bins_plot_grouping_2_box,
        )
            println("Plotting boxplot")
            plots_vector_box = []
            x = df[4][:, selected_plot_grouping_1_box[1]]
            y = df[4][:, selected_plot_traits_box[1]]
            z = if selected_plot_grouping_1_box == selected_plot_grouping_2_box
                repeat(["missing"], length(y))
            elseif length(selected_plot_grouping_2_box) > 0
                df[4][:, selected_plot_grouping_2_box[1]]
            else
                repeat(["missing"], length(y))
            end
            # Create x bins
            x = begin
                x_new = repeat(["missing"], length(x))
                idx = findall(.!ismissing.(x))
                if (length(idx) > 0) && !isa(x[idx[1]], String) 
                    idx = findall(.!ismissing.(x) .&& .!isnan.(x) .&& .!isinf.(x))
                    n = if n_bins_plot_grouping_1_box > length(x)
                        length(x)
                    else
                        n_bins_plot_grouping_1_box
                    end
                    unique_x = percentile(
                        filter(x -> !ismissing(x) && !isnan(x) && !isinf(x), x), 
                        100 .* collect(0:1/n:1)
                    )
                    m1 = length(split(string(maximum(round.(unique_x))), ".")[1])
                    m2 = 4
                    for (j, x_level) in enumerate(unique_x)
                        if j == 1
                            continue
                        end
                        idx_sub = if j == 2
                            # include the minimum
                            filter(i -> (x[i] >= unique_x[j-1]) && (x[i] <= unique_x[j]), idx)
                        else
                            filter(i -> (x[i] > unique_x[j-1]) && (x[i] <= unique_x[j]), idx)
                        end
                        ini = begin
                            ini = string((round(unique_x[j-1], digits=4)))
                            join([lpad(split(ini, ".")[1], m1, "0"), rpad(split(ini, ".")[2], m2, "0")], ".")
                        end
                        fin = begin
                            fin = string((round(unique_x[j], digits=4)))
                            join([lpad(split(fin, ".")[1], m1, "0"), rpad(split(fin, ".")[2], m2, "0")], ".")
                        end
                        x_new[idx_sub] .= string(ini, " - ", fin)
                    end
                else
                    x_new[idx] = x[idx]
                end
                x_new
            end
            # Create z bins
            z = begin
                z_new = repeat(["missing"], length(z))
                idx = findall(.!ismissing.(z))
                if (length(idx) > 0) && !isa(z[idx[1]], String) 
                    idx = findall(.!ismissing.(z) .&& .!isnan.(z) .&& .!isinf.(z))
                    n = if n_bins_plot_grouping_2_box > length(z)
                        length(z)
                    else
                        n_bins_plot_grouping_2_box
                    end
                    unique_z = percentile(
                        filter(z -> !ismissing(z) && !isnan(z) && !isinf(z), z), 
                        100 .* collect(0:1/n:1)
                    )
                    m1 = length(split(string(maximum(round.(unique_z))), ".")[1])
                    m2 = 4
                    for (j, z_level) in enumerate(unique_z)
                        if j == 1
                            continue
                        end
                        idx_sub = if j == 2
                            # include the minimum
                            filter(i -> (z[i] >= unique_z[j-1]) && (z[i] <= unique_z[j]), idx)
                        else
                            filter(i -> (z[i] > unique_z[j-1]) && (z[i] <= unique_z[j]), idx)
                        end
                        ini = begin
                            ini = string((round(unique_z[j-1], digits=4)))
                            join([lpad(split(ini, ".")[1], m1, "0"), rpad(split(ini, ".")[2], m2, "0")], ".")
                        end
                        fin = begin
                            fin = string((round(unique_z[j], digits=4)))
                            join([lpad(split(fin, ".")[1], m1, "0"), rpad(split(fin, ".")[2], m2, "0")], ".")
                        end
                        z_new[idx_sub] .= string(ini, " - ", fin)
                    end
                else
                    z_new[idx] = z[idx]
                end
                z_new
            end
            unique_z = sort(unique(z))
            colours_per_unique_z = try
                colorschemes[selected_plot_colour_scheme_box][1:length(unique_z)]
            catch
                repeat(
                    colorschemes[selected_plot_colour_scheme_box][1:end], 
                    outer=Int(ceil(length(unique_z)/length(colorschemes[selected_plot_colour_scheme_box])))
                )[1:length(unique_z)]
            end
            idx = findall(.!ismissing.(y) .&& .!isnan.(y) .&& .!isinf.(y))
            plots_vector_box = if length(idx) == 0
                []
            else
                plots_vector_box = []
                for z_level in sort(unique(z))
                    # Filter valid points
                    idx_sub = filter(j -> z[j] == z_level, idx)
                    push!(plots_vector_box, PlotlyBase.box(x=x[idx_sub], y=y[idx_sub], name=z_level, boxmean="sd"))
                end
                plots_vector_box
            end
            plots_layout_box = PlotlyBase.Layout(
                title=string("Boxplot of ", selected_plot_traits_box[1], "<br>    per ", selected_plot_grouping_1_box[1], " grouped by ", selected_plot_grouping_2_box[1]),
                xaxis_title=selected_plot_grouping_1_box[1],
                yaxis_title=selected_plot_traits_box[1],
                showlegend=true,
                legend=attr(title=attr(text=selected_plot_grouping_2_box[1])),
                boxmode="group",
                xaxis = attr(
                    categoryorder = "array",
                    categoryarray = sort(unique(x))
                ),
                colorway=colours_per_unique_z,
            )
            # Update plot
            Dict(
                "plotdata_box" => plots_vector_box,
                "plotlayout_box" => plots_layout_box,
            )
        end


        # When plot button clicked, create box plots for selected traits
        @in plot_table_box = false
        @onbutton plot_table_box begin
            p = reactivebox(
                df, 
                selected_plot_traits_box,
                selected_plot_grouping_1_box,
                selected_plot_grouping_2_box,
                selected_plot_colour_scheme_box,
                n_bins_plot_grouping_1_box,
                n_bins_plot_grouping_2_box,
            )
            plotdata_box = p["plotdata_box"]
            plotlayout_box = p["plotlayout_box"]
        end
    end

######################################################################################################################




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
                var"row-key" = ["name", "species", "ploidy", "crop_duration", "individual_or_pool", "maternal_family", "paternal_family", "cultivar", "population"],
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
            var"row-key" = ["species", "ploidy", "crop_duration", "individual_or_pool", "maternal_family", "paternal_family", "cultivar", "name", "population"],
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

    filters_dict = Dict(
        "00|Traits" => [:traits_filter_text, :traits_selected_options, :traits_filtered_options, btn("Select all", @click(:query_entries_select_all_traits), color = "primary", rounded=true, dense = true)],
        "01|Entries" => [:entries_filter_text, :entries_selected_options, :entries_filtered_options, btn("Select all", @click(:query_entries_select_all_entries), color = "primary", rounded=true, dense = true)],
        "02|Population" => [:populations_filter_text, :populations_selected_options, :populations_filtered_options, btn("Select all", @click(:query_entries_select_all_populations), color = "primary", rounded=true, dense = true)],
        "03|Years" => [:years_filter_text, :years_selected_options, :years_filtered_options, btn("Select all", @click(:query_entries_select_all_years), color = "primary", rounded=true, dense = true)],
        "04|Seasons" => [:seasons_filter_text, :seasons_selected_options, :seasons_filtered_options, btn("Select all", @click(:query_entries_select_all_seasons), color = "primary", rounded=true, dense = true)],
        "05|Harvests" => [:harvests_filter_text, :harvests_selected_options, :harvests_filtered_options, btn("Select all", @click(:query_entries_select_all_harvests), color = "primary", rounded=true, dense = true)],
        "06|Sites" => [:sites_filter_text, :sites_selected_options, :sites_filtered_options, btn("Select all", @click(:query_entries_select_all_sites), color = "primary", rounded=true, dense = true)],
        "07|Individuals or pools" => [:individuals_or_pools_filter_text, :individuals_or_pools_selected_options, :individuals_or_pools_filtered_options, btn("Select all", @click(:query_entries_select_all_individuals_or_pools), color = "primary", rounded=true, dense = true)],
        "08|Species" => [:species_filter_text, :species_selected_options, :species_filtered_options, btn("Select all", @click(:query_entries_select_all_species), color = "primary", rounded=true, dense = true)],
        "09|Ploidies" => [:ploidies_filter_text, :ploidies_selected_options, :ploidies_filtered_options, btn("Select all", @click(:query_entries_select_all_ploidies), color = "primary", rounded=true, dense = true)],
        "10|Crop duration" => [:crop_durations_filter_text, :crop_durations_selected_options, :crop_durations_filtered_options, btn("Select all", @click(:query_entries_select_all_crop_durations), color = "primary", rounded=true, dense = true)],
        "11|Maternal families" => [:maternal_families_filter_text, :maternal_families_selected_options, :maternal_families_filtered_options, btn("Select all", @click(:query_entries_select_all_maternal_families), color = "primary", rounded=true, dense = true)],
        "12|Paternal families" => [:paternal_families_filter_text, :paternal_families_selected_options, :paternal_families_filtered_options, btn("Select all", @click(:query_entries_select_all_paternal_families), color = "primary", rounded=true, dense = true)],
        "13|Cultivars" => [:cultivars_filter_text, :cultivars_selected_options, :cultivars_filtered_options, btn("Select all", @click(:query_entries_select_all_cultivars), color = "primary", rounded=true, dense = true)],
        "14|Replications" => [:replications_filter_text, :replications_selected_options, :replications_filtered_options, btn("Select all", @click(:query_entries_select_all_replications), color = "primary", rounded=true, dense = true)],
        "15|Blocks" => [:blocks_filter_text, :blocks_selected_options, :blocks_filtered_options, btn("Select all", @click(:query_entries_select_all_blocks), color = "primary", rounded=true, dense = true)],
        "16|Rows" => [:rows_filter_text, :rows_selected_options, :rows_filtered_options, btn("Select all", @click(:query_entries_select_all_rows), color = "primary", rounded=true, dense = true)],
        "17|Columns" => [:cols_filter_text, :cols_selected_options, :cols_filtered_options, btn("Select all", @click(:query_entries_select_all_cols), color = "primary", rounded=true, dense = true)],        
    )
    filters = [
        expansionitem(label=string(split(string(k), "|")[end]), expandseparator=true, [
            textfield(
                string(split(string(k), "|")[end]),
                @bind(v[1]),
                outlined=true,
                dense=true,
                clearable=true,
                rounded=true,
            ),
            v[4],
            Stipple.select(
                v[2],
                options=v[3],
                useinput=true, 
                multiple = true,
                clearable = true,
                usechips = true,
                counter = true,
                dense = true,
                autofocus = true,
            ),
        ]) for (k, v) in sort(filters_dict)
    ]

    [
        filters...,
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
        toggle("Include phenotype data?", :phenotype_data, color = "green", var"true-value" = "yes", var"false-value" = "no",),
        toggle("Include genotype data?", :genotype_data, color = "blue", var"true-value" = "yes", var"false-value" = "no",),
        p("\t"),
        btn("Clear all filters", @click(:query_entries_clear_all_filters), color = "primary", rounded=true, dense = true),
        p("\t"),
        btn("Download", icon = "download", @on(:click, :download_entries), color = "primary", nocaps = true),
        separator(color = "primary"),
        Stipple.table(
            :table_query_entries,
            flat = true,
            bordered = true,
            title = "Entries",
            var"row-key" = ["species", "ploidy", "crop_duration", "individual_or_pool", "maternal_family", "paternal_family", "cultivar", "name", "population", "year", "season", "harvest", "site", "replication", "block", "row", "col"],
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
        row([
            column(size=3, [Stipple.select(:selected_table_to_plot_hist, useinput=true, options = :choices_tables_to_plot_hist, label = "Table to plot"),]),
            column(size=3, [Stipple.select(:selected_plot_traits_hist, useinput=true, options = :choices_plot_traits_hist, label = "Traits", multiple=true, usechips=true),]),
            column(size=3, [Stipple.select(:selected_agg_func_per_season_hist, useinput=true, options = :choices_agg_func_per_season_hist, label = "Aggregator per season", multiple=false, usechips=false),]),
        ]),
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
        row([
            column(size=3, [Stipple.select(:selected_table_to_plot_scat, useinput=true, options = :choices_tables_to_plot_scat, label = "Table to plot"),]),
            column(size=3, [Stipple.select(:selected_plot_traits_scat_x, useinput=true, options = :choices_plot_traits_scat_x, label = "Trait x", multiple=false, usechips=false),]),
            column(size=3, [Stipple.select(:selected_plot_traits_scat_y, useinput=true, options = :choices_plot_traits_scat_y, label = "Trait y", multiple=false, usechips=false),]),
            column(size=3, [Stipple.select(:selected_plot_traits_scat_z, useinput=true, options = :choices_plot_traits_scat_z, label = "Grouping", multiple=false, usechips=false),]),
        ]),
        row([
            column(size=3, [Stipple.select(:selected_plot_colour_scheme_scat, useinput=true, options = :choices_plot_colour_scheme_scat, label = "Colour Scheme", multiple=false, usechips=false),]),
            column(size=3, [Stipple.select(:selected_agg_func_per_season_scat_x, useinput=true, options = :choices_agg_func_per_season_scat, label = "x-aggregator per season", multiple=false, usechips=false),]),
            column(size=3, [Stipple.select(:selected_agg_func_per_season_scat_y, useinput=true, options = :choices_agg_func_per_season_scat, label = "y-aggregator per season", multiple=false, usechips=false),]),
        ]),
        btn(
            "Plot",
            @click(:plot_table_scat),
            loading = :plot_table_scat,
            color = "green",
        ),
        StipplePlotly.plot(:plotdata_scat, layout=:plotlayout_scat, class="sync_data")
    ]
end

function uiplotpca()
    [
        row([
            column(size=3, [Stipple.select(:selected_table_to_plot_pca, useinput=true, options = :choices_tables_to_plot_pca, label = "Table to plot"),]),
            column(size=3, [Stipple.select(:selected_plot_traits_pca_x, useinput=true, options = :choices_plot_traits_pca_x, label = "Trait x", multiple=false, usechips=false),]),
            column(size=3, [Stipple.select(:selected_plot_traits_pca_y, useinput=true, options = :choices_plot_traits_pca_y, label = "Trait y", multiple=false, usechips=false),]),
            column(size=3, [Stipple.select(:selected_plot_traits_pca_z, useinput=true, options = :choices_plot_traits_pca_z, label = "Grouping", multiple=false, usechips=false),]),
        ]),
        row([
            column(size=3, [Stipple.select(:selected_plot_colour_scheme_pca, useinput=true, options = :choices_plot_colour_scheme_pca, label = "Colour Scheme", multiple=false, usechips=false),]),
            # column(size=3, [Stipple.select(:selected_agg_func_per_season_pca_x, useinput=true, options = :choices_agg_func_per_season_pca, label = "x-aggregator per season", multiple=false, usechips=false),]),
            # column(size=3, [Stipple.select(:selected_agg_func_per_season_pca_y, useinput=true, options = :choices_agg_func_per_season_pca, label = "y-aggregator per season", multiple=false, usechips=false),]),
        ]),
        btn(
            "Plot",
            @click(:plot_table_pca),
            loading = :plot_table_pca,
            color = "green",
        ),
        StipplePlotly.plot(:plotdata_pca, layout=:plotlayout_pca, class="sync_data")
    ]
end

function uiplotbox()
    [
        row([
            column(size=3, [
                Stipple.select(:selected_table_to_plot_box, useinput=true, options = :choices_tables_to_plot_box, label = "Table to plot"),
                ]),
            column(size=3, [
                Stipple.select(:selected_plot_traits_box, useinput=true, options = :choices_plot_traits_box, label = "Traits", multiple=false, usechips=false),
            ]),
            column(size=3, [
                Stipple.select(:selected_plot_grouping_1_box, useinput=true, options = :choices_plot_grouping_1_box, label = "Grouping 1", multiple=false, usechips=false),
            ]),
            column(size=3, [
                Stipple.select(:selected_plot_grouping_2_box, useinput=true, options = :choices_plot_grouping_2_box, label = "Grouping 2", multiple=false, usechips=false),
            ]),
            column(size=3, [
                Stipple.select(:selected_plot_colour_scheme_box, useinput=true, options = :choices_plot_colour_scheme_box, label = "Colour Scheme", multiple=false, usechips=false),
            ]),
        ]),
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
                tab(name = "pca",
                    label = "PCA biplot"
                ),
                tab(name = "boxplot",
                    label = "Boxplot"
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
                tabpanel(name = "pca", uiplotpca()),
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
