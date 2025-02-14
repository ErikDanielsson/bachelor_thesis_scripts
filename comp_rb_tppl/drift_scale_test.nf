nextflow.enable.dsl=2

params.simdir = file("driftscale_param_sim")
params.outdir = params.simdir / "output"
params.datadir = params.simdir / "datadir"
params.bindir = params.simdir / "bindir"
params.time = false
params.ngens = 2
params.nruns = 3
params.niter = 1e4
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
    compile_hostrep_treeppl;
    run_hostrep_treeppl;
    time_hostrep_treeppl
} from "./modules/treeppl"

workflow {
    // Define the simulations
    genid = Channel.of((1..params.ngens)) 
    runid = Channel.of((1..params.nruns))
    drift_scale = Channel.of(1.0, 0.1, 0.01)
    gprob = Channel.of(0.0)

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

    // Create all the combinations of compiler flags we desire
    // and give each a unique id
    compile_id = 0
    compile_in_ch = runid.combine(drift_scale).combine(gprob) 
        .map {runid, drift_scale, gprob -> [compile_id++, runid, drift_scale, gprob]}

    // Save the parameter combination corresponding to each compile id to a file
    compile_in_ch.collectFile(
        name: "compile_id_to_param_comb.csv",
        storeDir: file(params.outdir),
        newLine: true
    ) {compile_id, runid, drift_scale, gprob -> "$compile_id\t$runid\t$drift_scale\t$gprob"}

    // Create all binaries we require
    compile_hostrep_treeppl(
        compile_in_ch,
    )

    // Create the in file channel
    // -- all combinations of compiler flags and data generations
    treeppl_in_ch = compile_hostrep_treeppl.out.hostrep_bin.combine(
        clean_phyjson.out.phyjson
    )

    // Run the treeppl implementation
    treeppl_out_ch = run_hostrep_treeppl(
        treeppl_in_ch,
        niter,
    ) 
}