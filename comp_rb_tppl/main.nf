"""
Nextflow pipeline for performance comparison between
the RevBayes and TreePPL implementation of the host repertoire model
"""
nextflow.enable.dsl=2

params.time = false
params.nsims = 3
params.niter = 1e3
params.subsample = 1
params.nhosts = 3
params.nsymbionts = 3

include {
    generate_trees_and_interactions;
    rev_annotate_tree;
    generate_phyjson;
    clean_phyjson
} from "./modules/gendata"

include {
    run_hostrep_revbayes;
    time_hostrep_revbayes
} from "./modules/revbayes"

include {
    compile_hostrep_treeppl;
    run_hostrep_treeppl;
    time_hostrep_treeppl
} from "./modules/treeppl"

include {
    generate_trace_plots
} from "./modules/analysis"

workflow {
    // Define the simulations
    genid = Channel.of((1..1)) 
    runid = Channel.of((1..10))
    nhosts = params.nhosts
    nsymbionts = params.nsymbionts

    int niter = (int)params.niter
    int freq_subsample = (int)params.subsample

    // Generate data from a coalescent model
    generate_trees_and_interactions(
        genid,
        nsymbionts,
        nhosts,
    )

    // Pass the symbiont tree through revbayes to give it node labels
    rev_annotate_tree(
        genid,
        generate_trees_and_interactions.out.symbiont_tree.map {genid, tree -> tree}
    )
    // Generate the phyJSON
    generate_phyjson(
        genid,
        rev_annotate_tree.out.rev_tree.map  {genid, tree -> tree},
        generate_trees_and_interactions.out.host_tree.map {genid, tree -> tree},
        generate_trees_and_interactions.out.interactions_csv.map {genid, file -> file}
    )

    clean_phyjson(
        genid,
        generate_phyjson.out.dirty_phyjson.map {genid, tree -> tree}
    )


    // Compile the host repertoire model to an executable
    compile_hostrep_treeppl()
    def treeppl_out_ch
    def revbayes_out_ch

    rev_bayes_in_ch = runid.combine(
        generate_trees_and_interactions.out.symbiont_tree
        .join(generate_trees_and_interactions.out.host_tree)
        .join(generate_trees_and_interactions.out.interactions_nex)
    )

    treeppl_in_ch = runid.combine(
        clean_phyjson.out.phyjson
    )

    // Execute the correct type of simulation for the model
    if ( params.time ) {
        // Time the treeppl implementation
        treeppl_out_ch = time_hostrep_treeppl(
            treeppl_in_ch,
            niter,
            compile_hostrep_treeppl.out.hostrep_bin.first(),
        )

        // Time the revbayes implementation
        revbayes_out_ch = time_hostrep_revbayes(
            rev_bayes_in_ch,
            niter,
            freq_subsample,
        )
    } else {
        // Run the treeppl implementation
        treeppl_out_ch = run_hostrep_treeppl(
            treeppl_in_ch,
            niter,
            compile_hostrep_treeppl.out.hostrep_bin.first(),
        ) 

        // Run the revbayes implementation
        revbayes_out_ch = run_hostrep_revbayes(
            rev_bayes_in_ch,
            niter,
            freq_subsample,
        )
    }

    generate_trace_plots(
        revbayes_out_ch.clock_log.map {runid, log -> log}.collect(),
        treeppl_out_ch.output_json.map {runid, out -> out}.collect()
    ) 
}