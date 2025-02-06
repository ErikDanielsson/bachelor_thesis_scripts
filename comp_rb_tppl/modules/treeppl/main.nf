process compile_hostrep_treeppl {
    publishDir "gen_bin"

    output:
        path "hostrep.bin", emit: hostrep_bin
    
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
        val niter
        path hostrep_bin
        tuple val(genid), path(phyjson_file) 
    
    output:
        tuple val(simid), path("output.${simid}.json"), emit: output_json
    
    script:
    """
    ./${hostrep_bin} ${phyjson_file} ${niter} > output.${simid}.json
    """
}

process time_hostrep_treeppl {
    publishDir "output"

    input:
        val simid
        val niter
        path hostrep_bin
        path phyjson_file
    
    output:
        tuple val(simid), path("time.treeppl.${simid}.txt"), emit: time
        tuple val(simid), path("output.${simid}.json"), emit: output_json
    
    script:
    """
    { time \
        ./${hostrep_bin} ${phyjson_file} ${niter} \
        1> output.${simid}.json \
        2> /dev/null; \
    } 2> "time.treeppl.${simid}.txt"
    """
}

process perf_hostrep_treeppl {
    publishDir "output"

    input:
        val simid
        val niter
        path hostrep_bin
        path phyjson_file
    
    output:
        path "time.treeppl.${simid}.txt"
        path "output.${simid}.json" 
    
    script:
    """
    { perf \
        ./${hostrep_bin} ${phyjson_file} ${niter} \
        1> output.${simid}.json \
        2> /dev/null; \
    } 2> "time.treeppl.${simid}.txt"
    """
}