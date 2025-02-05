"""
Nextflow pipeline for performance copa
"""

include {
    generate_trees_and_interactions;
    rev_annotate_tree;
    generate_phyjson;
    clean_phyjson
} from "./modules/gendata"

include {
    run_hostrep_revbayes
} from "./modules/revbayes"

include {
    compile_hostrep_treeppl;
    run_hostrep_treeppl
} from "./modules/treeppl"

workflow {
    // Define the simulations
    simid = Channel.of((1..3))

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

    // Run the revbayes implementation
    run_hostrep_revbayes(
        simid,
        generate_trees_and_interactions.out[0],
        generate_trees_and_interactions.out[1],
        generate_trees_and_interactions.out[3]
    )
}