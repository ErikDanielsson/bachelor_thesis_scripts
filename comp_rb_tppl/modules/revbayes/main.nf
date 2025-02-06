process run_hostrep_revbayes {
    publishDir "output"

    input:
        val(simid)
        val niter
        val freq_subsample
        tuple val(genid), path(symbiont_tree_file)
        tuple val(genid), path(host_tree_file)
        tuple val(genid), path(interactions_nex_file)

    output:
        tuple val(simid), path("out.${simid}.logger.log"), emit: clock_log
        tuple val(simid), path("out.${simid}.log"), emit: model_log
        tuple val(simid), path("out.${simid}.history.txt"), emit: character_summary_log
        tuple val(simid), path("out.${simid}.tre"), emit: phy_symbiont_log
    
    script:
    """
    rb $baseDir/scripts/Infer_test.Rev \
        --args $simid \
        --args $niter \
        --args $freq_subsample \
        --args $host_tree_file \
        --args $symbiont_tree_file \
        --args $interactions_nex_file \
        --args \$PWD
    """
}

process time_hostrep_revbayes {
    publishDir "output"

    input:
        val simid
        val niter
        val freq_subsample
        tuple val(simid), path(symbiont_tree_file)
        tuple val(simid), path(host_tree_file)
        tuple val(simid), path(interactions_nex_file)


    output:
        tuple val(simid), path("time.revbayes.${simid}.txt"), emit: time
        tuple val(simid), path("out.${simid}.logger.log"), emit: clock_log
        tuple val(simid), path("out.${simid}.log"), emit: model_log
        tuple val(simid), path("out.${simid}.history.txt"), emit: character_summary_log
        tuple val(simid), path("out.${simid}.tre"), emit: phy_symbiont_log
   
    script:
    """
    { time rb $baseDir/scripts/Infer_test.Rev \
        --args $simid \
        --args $niter \
        --args $freq_subsample \
        --args $host_tree_file \
        --args $symbiont_tree_file \
        --args $interactions_nex_file \
        --args \$PWD; \
    } 2> time.revbayes.${simid}.txxt
    """
}