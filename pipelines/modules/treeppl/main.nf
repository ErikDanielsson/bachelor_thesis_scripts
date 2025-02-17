params.outdir = "test_output"
params.bindir = "test_gen_bin"

process compile_hostrep_treeppl {

    publishDir "${params.bindir}"

    input:
        tuple val(compile_id), val(runid), val(drift_scale), val(gprob)

    output:
        tuple val(compile_id), path("hostrep.${compile_id}.bin"), emit: hostrep_bin
    
    script:
    """
    tpplc $baseDir/models/host_repertoire.tppl \
        -m mcmc-lw-dk \
        --align \
        --cps none \
        --kernel \
        --drift ${drift_scale}\
        --mcmc-lw-gprob ${gprob} \
        --output hostrep.${compile_id}.bin \
        --seed ${runid}
    chmod +x hostrep.${compile_id}.bin
    """

    stub:
    """
    touch hostrep.${compile_id}.bin
    chmod +x hostrep.${compile_id}.bin
    """
}

process run_hostrep_treeppl {
    /*
    The treeppl implementation is light in memory use for most of the
    execution but uses a lot of memory at the end of the execution (upwards of
    10Gb). This is a hacky way of trying many runs at first, and then settling
    for fewer if they collide to much
    */
    memory { 1.5.GB * Math.pow(2, task.attempt - 1) }
    maxRetries 5 
    errorStrategy { task.exitStatus == 137 ? 'retry' : 'terminate' }

    publishDir "${params.outdir}"

    input:
        tuple val(compile_id), path(hostrep_bin), val(genid), path(phyjson_file) 
        val niter
    
    output:
        tuple val(genid), val(compile_id), path("output.${genid}.${compile_id}.json"), emit: output_json
    
    script:
    """
    ./${hostrep_bin} ${phyjson_file} ${niter} > output.${genid}.${compile_id}.json
    """

    stub:
    """
    touch output.${genid}.${compile_id}.json
    """
}

process time_hostrep_treeppl {
    memory { 2.GB * Math.pow(2, task.attempt - 1) }
    maxRetries 5 

    publishDir "${params.outdir}"

    input:
        tuple val(runid), path(hostrep_bin), val(genid), path(phyjson_file) 
        val niter

    output:
        tuple val(runid), path("time.treeppl.${genid}.${runid}.txt"), emit: time
        tuple val(runid), path("output.${genid}.${runid}.json"), emit: output_json
    
    script:
    """
    { time \
        ./${hostrep_bin} ${phyjson_file} ${niter} \
        1> output.${genid}.${runid}.json \
        2> /dev/null; \
    } 2> "time.treeppl.${genid}.${runid}.txt"
    """


}

process perf_hostrep_treeppl {
    publishDir "${params.outdir}"

    input:
        val runid
        val niter
        path hostrep_bin
        path phyjson_file
    
    output:
        path "time.treeppl.${runid}.txt"
        path "output.${runid}.json" 
    
    script:
    """
    { perf \
        ./${hostrep_bin} ${phyjson_file} ${niter} \
        1> output.${runid}.json \
        2> /dev/null; \
    } 2> "time.treeppl.${runid}.txt"
    """
}