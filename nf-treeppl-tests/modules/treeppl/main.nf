process compile_model {
    label 'compile'
    container "${ params.container_treeppl }"

    input:
        tuple val(compile_id), val(runid), val(model_id), path(model_fn), val(inference_flags)

    output:
        tuple val(compile_id), path("${model_id}.${compile_id}.bin"), emit: bin
    
    script:
    def out_fn = "${model_id}.${compile_id}.bin"
    """
    tpplc ${model_fn} \
        --output ${out_fn} \
        --seed ${runid} \
        ${inference_flags}
    chmod +x ${out_fn}
    """

    stub:
    def model_fn = "${model_path}/model.tppl"
    def out_fn = "${model_id}.${compile_id}.bin"
    """
    ls -la
    cat ${model_fn} 
    echo ${inference_flags} > ${out_fn}
    chmod +x ${out_fn}
    """
}

process run_model {
    label 'sim'
    container "${ params.container_treeppl }"

    input:
        tuple val(compile_id), path(hostrep_bin), path(data_path) 
        val niter
    
    output:
        tuple val(compile_id), path("output.${compile_id}.json"), emit: output_json
    
    script:
    """
    ./${hostrep_bin} $data_path ${niter} > output.${compile_id}.json
    """

    stub:
    """
    touch output.${compile_id}.json
    """
}