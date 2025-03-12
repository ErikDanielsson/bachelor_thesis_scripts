include {
    compile_model;
    run_model;
} from "./modules/treeppl"

include {
    generate_plot;
    compute_GoF;
} from "./modules/analysis"

include {
    run_comparison
} from "./modules/compare"

workflow {
    // Define the simulations
    def runid = Channel.of((1..params.nruns))
    int niter = (int)params.niter
    
    // Get the compile flags
    compile_flags = Channel.fromPath(params.compile_flags)
        | splitCsv(sep:"\t", header:["alg_type", "compile_flags"])
        | map {row -> [row.alg_type, row.compile_flags]}

    // Get the model names
    model_id = 0
    model_ch = Channel.fromPath(params.models)
        .splitCsv(sep:"\t", header:["model_dir", "model_name"])
        .map {row -> [model_id++, row.model_dir, row.model_name]}
    
    // Compute the model paths
    model_path_ch = model_ch
        .map {mid, md, mn -> [mid, "$baseDir/models/${md}/${mn}/"]}

    compare_in_ch = model_path_ch
        .map {mid, mp -> [mid, "$mp/compare.py", "$mp/data.json"]}
    run_comparison(compare_in_ch, niter)

    compile_id = 0
    combined_ch = runid.combine(model_path_ch).combine(compile_flags)
        .map {
            rid, mid, mp, algt, flags ->
            [compile_id++, rid, mid, mp, algt, flags]
        }

    
    config_file_ch = combined_ch.collectFile(
        name: "compile_id_to_configuration.csv",
        storeDir: file(params.bindir),
        newLine: true
    ) {t -> t.join("\t")}

    compile_in_ch = combined_ch
        .map {cid, rid, mid, mp, algt, flags -> [cid, rid, mid, "$mp/model.tppl", flags]}

    compile_model(compile_in_ch)

    run_in_ch = compile_model.out.bin.join(
        combined_ch
            .map {cid, rid, mid, mp, algt, flags -> [cid, "$mp/data.json"]}
    )

    run_model(run_in_ch, niter)  

    cid_mid_ch = combined_ch
        .map {cid, rid, mid, mp, algt, flags -> [cid, mid]}

    post_analysis_in_ch = cid_mid_ch
        .join(run_model.out.output_json)
        .map {cid, mid, outf -> [mid, cid, outf]}
        .groupTuple(by: [0])
        .join(model_ch)
        .join(model_path_ch)
        .join(run_comparison.out.output_json)
        
    generate_plot(
        post_analysis_in_ch,
        config_file_ch.first(),
    )

    compute_GoF(
        post_analysis_in_ch,
        config_file_ch.first(),
    ) 
}