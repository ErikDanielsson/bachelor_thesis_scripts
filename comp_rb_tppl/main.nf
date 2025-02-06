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
    genid = 1 
    simid = Channel.of((1..3))
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

    clean_phyjson.out.collect().view()

    // Compile the host repertoire model to an executable
    compile_hostrep_treeppl()
    def treeppl_out_ch
    def revbayes_out_ch

    // Execute the correct type of simulation for the model
    if ( params.time ) {
        treeppl_out_ch = time_hostrep_treeppl(
            simid,
            niter,
            compile_hostrep_treeppl.out,
            clean_phyjson.out,
        )

        // Run the revbayes implementation
        revbayes_out_ch = time_hostrep_revbayes(
            simid,
            niter,
            generate_trees_and_interactions.out.symbiont_tree,
            generate_trees_and_interactions.out.host_tree,
            generate_trees_and_interactions.out.interactions_nex
        )
    } else {
        treeppl_out_ch = run_hostrep_treeppl(
            simid,
            niter,
            compile_hostrep_treeppl.out.hostrep_bin.first(),
            clean_phyjson.out.phyjson.first()
        ) 
        run_hostrep_treeppl.out.output_json.view()
        // Run the revbayes implementation
        revbayes_out_ch = run_hostrep_revbayes(
            simid,
            niter,
            freq_subsample,
            generate_trees_and_interactions.out.symbiont_tree.first(),
            generate_trees_and_interactions.out.host_tree.first(),
            generate_trees_and_interactions.out.interactions_nex.first()
        )
        run_hostrep_revbayes.out.clock_log.view()
    }

    generate_trace_plots(
        run_hostrep_revbayes.out.clock_log.map {simid, log -> log}.collect(),
        run_hostrep_treeppl.out.output_json.map {simid, out -> out}.collect()
    ) 
}