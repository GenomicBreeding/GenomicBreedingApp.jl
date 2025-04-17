module GenomicBreedingApp

using GenieFramework

# Place the main @app definition and related logic from the previous app.jl here
# OR keep app.jl in the root and just use this module file for structure.
# Let's assume app.jl stays in the root for this example,
# so this file just sets up the module context.

const up = Genie.up
const down = Genie.down

function main()
  Genie.genie(; context = @__MODULE__)
end

end