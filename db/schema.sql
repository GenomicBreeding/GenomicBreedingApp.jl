-- PostgreSQL Schema for Genomic Breeding (Optimized for VCF and Performance)

-- Genetic entries (e.g., varieties, hybrids)
CREATE TABLE IF NOT EXISTS entries (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    species TEXT NOT NULL,
    population TEXT,
    classification TEXT,
    description TEXT
);

-- Traits (e.g., yield, height)
CREATE TABLE IF NOT EXISTS traits (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    description TEXT
);


-- Yield trials metadata
CREATE TABLE IF NOT EXISTS trials (
    id SERIAL PRIMARY KEY,
    year INT,
    season TEXT,
    harvest TEXT,
    site TEXT,
    block TEXT,
    row TEXT,
    col TEXT,
    replication TEXT
);

-- Phenotype measurements
CREATE TABLE IF NOT EXISTS phenotype_data (
    id SERIAL PRIMARY KEY,
    entry_id INT REFERENCES entries(id),
    trait_id INT REFERENCES traits(id),
    trial_id INT REFERENCES trials(id),
    value FLOAT,
    CHECK (value IS NULL OR value != 'NaN'::FLOAT)
);

-- Analyses metadata
CREATE TABLE IF NOT EXISTS analyses (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    description TEXT
);

-- Entry × Trait × Trial tagging for inclusion in specific analyses
CREATE TABLE IF NOT EXISTS analysis_tags (
    id SERIAL PRIMARY KEY,
    analysis_id INT REFERENCES analyses(id),
    entry_id INT REFERENCES entries(id),
    trait_id INT REFERENCES traits(id),
    trial_id INT REFERENCES trials(id),
    UNIQUE (analysis_id, entry_id, trait_id, trial_id)
);

-- TODO: GENOTYPE DATA
-- -- Reference genomes
-- CREATE TABLE IF NOT EXISTS reference_genomes (
--     id SERIAL PRIMARY KEY,
--     name TEXT UNIQUE NOT NULL,
--     description TEXT
-- );
-- Variants (VCF-style markers)
-- CREATE TABLE IF NOT EXISTS variants (
--     id SERIAL PRIMARY KEY,
--     reference_genome_id INT REFERENCES reference_genomes(id),
--     chrom TEXT,
--     pos INT,
--     ref TEXT,
--     alt TEXT,
--     name TEXT,
--     UNIQUE(reference_genome_id, chrom, pos)
-- );

-- -- Genotype matrix (entry × variant, VCF-style data)
-- CREATE TABLE IF NOT EXISTS genotype_data (
--     id SERIAL PRIMARY KEY,
--     entry_id INT REFERENCES entries(id),
--     variant_id INT REFERENCES variants(id),
--     genotype TEXT,         -- e.g., '0/1'
--     phred_quality REAL,    -- Optional: VCF QUAL field
--     depth INT,             -- Optional: VCF DP field
--     UNIQUE(entry_id, variant_id)
-- );

-- Add constraints for inserting data (critical for upload...() functions)
ALTER TABLE entries ADD CONSTRAINT unique_entry_instance UNIQUE (name, species);
ALTER TABLE trials ADD CONSTRAINT unique_trial_instance UNIQUE (year, season, harvest, site, block, row, col, replication);
ALTER TABLE phenotype_data ADD CONSTRAINT unique_phenotype_measurement UNIQUE (entry_id, trait_id, trial_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_phenotype_entry_trait_trial ON phenotype_data (entry_id, trait_id, trial_id);
CREATE INDEX IF NOT EXISTS idx_analysis_tag_lookup ON analysis_tags (analysis_id, entry_id, trait_id);
-- CREATE INDEX IF NOT EXISTS idx_genotype_entry_variant ON genotype_data (entry_id, variant_id);
-- CREATE INDEX IF NOT EXISTS idx_variant_position ON variants (reference_genome_id, chrom, pos);

-- Add extensions
CREATE EXTENSION pg_trgm; -- fuzzy matching

-- Create a GIN index for fuzzy search lookup performance on entry, site and trait names
CREATE INDEX trgm_entries_name_idx ON entries USING GIN (name gin_trgm_ops);
CREATE INDEX trgm_trials_site_idx ON trials USING GIN (site gin_trgm_ops);
CREATE INDEX trgm_traits_name_idx ON traits USING GIN (name gin_trgm_ops);