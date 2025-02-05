process run_hostrep_revbayes {
    publishDir "output"

    input:
        val simid
        path symbiont_tree_file
        path host_tree_file
        path interactions_nex_file


    output:
        path "out.${simid}.logger.log"
        path "out.${simid}.log"
        path "out.${simid}.history.txt"
        path "out.${simid}.tre"
    
    script:
    """
    rb $baseDir/scripts/Infer_test.Rev \
        --args $simid \
        --args $host_tree_file \
        --args $symbiont_tree_file \
        --args $interactions_nex_file \
        --args \$PWD
    """
}