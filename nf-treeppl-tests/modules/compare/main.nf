process run_comparison {
    label 'sim'
    container "${ params.container_python }"

    input:
        tuple val(model_id), path(compare_path), path(data_path)
        val niter
    
    output:
        tuple val(model_id), path("compare.${model_id}.json"), emit: output_json
    
    script:
    """
    python $compare_path $data_path ${niter} compare.${model_id}.json
    """

    stub:
    """
    touch "compare.${model_id}.json"
    """
}