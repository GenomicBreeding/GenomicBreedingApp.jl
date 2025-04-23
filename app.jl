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
# Import all neccesary GenieFramework.jl components
@genietools
# Define the reactive parts of the app (i.e. the inputs and outputs)
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
