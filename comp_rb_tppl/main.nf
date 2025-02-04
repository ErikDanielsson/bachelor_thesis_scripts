"""
Nextflow pipeline for performance copa
"""


process generate_trees_and_interactions {
    publishDir "gen_data"

    input:
        val simid

    output:
        path "parasite_tree.${simid}.tre"
        path "host_tree.${simid}.tre"
        path "interactions.${simid}.csv"
        path "interactions.${simid}.nex"

    script:
    """
    Rscript $baseDir/scripts/generate_data.R ${simid}
    """
}

process rev_annotate_tree {
    publishDir "gen_data"

    input:
        val simid
        path input

    output:
        path "${input.getBaseName()}" + ".rev.tre"

    script:
    """
    rb $baseDir/scripts/annotate_tree.Rev --args ${input} --args ${input.baseName}.rev.tre
    """
}

process generate_phyjson {
    input:
        val simid
        path symbiont_tree_file
        path host_tree_file
        path interactions_csv_file

    output:
        path "dirty_host_parasite${simid}.json"
    
    script:
    """
    Rscript $baseDir/scripts/transform_data_to_phyjson.R ${symbiont_tree_file} ${host_tree_file} ${interactions_csv_file} "dirty_host_parasite${simid}.json"
    """
}

process clean_phyjson {
    publishDir "gen_data"

    input:
        val simid
        path dirty_phyjson

    output:
        path "host_parasite${simid}.json"

    script:
    """
    python $baseDir/scripts/clean_phyjson.py ${dirty_phyjson} "host_parasite${simid}.json"
    """
}

process compile_hostrep_treeppl {
    publishDir "gen_bin"

    output:
        path "hostrep.bin"
    
    script:
    """
    tpplc $baseDir/treeppl/host_repertoire.tppl --output hostrep.bin
    chmod +x hostrep.bin
    """
}

process run_hostrep_treeppl {
    publishDir "output"

    input:
        val simid
        path hostrep_bin
        path phyjson_file
        val niter
    
    output:
        path "output${simid}.json" 
    
    script:
    """
    ./${hostrep_bin} ${phyjson_file} ${niter} > "output${simid}.json"
    """
}

workflow {
    // Define the simulations
    simid = Channel.of((1..1))

    // Generate data from a coalescent model
    generate_trees_and_interactions(simid)

    // Pass the symbiont tree through revbayes to give it node labels
    rev_annotate_tree(
        simid,
        generate_trees_and_interactions.out[0]
    )

    // Generate the phyJSON
    generate_phyjson(
        simid,
        rev_annotate_tree.out,
        generate_trees_and_interactions.out[1],
        generate_trees_and_interactions.out[2]
    )
    clean_phyjson(
        simid,
        generate_phyjson.out
    )

    // Compile the host repertoire model to an executable
    compile_hostrep_treeppl()

    // Execute the correct type of simulation for the model
    run_hostrep_treeppl(
        simid,
        compile_hostrep_treeppl.out,
        clean_phyjson.out,
        10
    )
}