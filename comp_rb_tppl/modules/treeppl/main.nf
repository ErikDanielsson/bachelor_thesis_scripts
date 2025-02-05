process compile_hostrep_treeppl {
    publishDir "gen_bin"

    output:
        path "hostrep.bin"
    
    script:
    """
    tpplc $baseDir/scripts/host_repertoire.tppl \
        -m mcmc-lw-dk \
        --align \
        --cps none \
        --kernel \
        --drift 0.1\
        --mcmc-lw-gprob 0.0 \
        --output hostrep.bin
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