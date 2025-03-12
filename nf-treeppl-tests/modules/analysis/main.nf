process generate_plot {
    label 'analysis'

    container "${ params.container_python }"    
    debug true

    input:
        tuple val(model_id), val(cids), path(outfiles), val(model_dir), val(model_name), path(model_path), path(comp_path)
        path compile_config

    output:
        path "histplot.${model_dir}.${model_name}.*.png", emit: runs_png

    script:
    def csv_fn = "runs.${model_id}.csv"
    def plot_fn_prefix = "histplot.${model_dir}.${model_name}"
    def out_desc_fn = "$model_path/output_description.csv"
    """
    echo "compile_id\tfile_name" >> $csv_fn
    paste -d "\t" \
        <(echo "${cids.join(' ')}"     | tr ' ' '\n' ) \
        <(echo "${outfiles.join(' ')}" | tr ' ' '\n' ) \
        >> $csv_fn
    
    generate_histplot.py $compile_config $csv_fn $out_desc_fn $comp_path $plot_fn_prefix 
    """

    stub:
    def csv_fn = "runs.${model_id}.csv"
    def plot_fn = "histplot.${model_dir}.${model_name}.png"
    """
    echo "compile_id\tfile_name" >> $csv_fn
    paste -d "\t" \
        <(echo "${cids.join(' ')}"     | tr ' ' '\n' ) \
        <(echo "${outfiles.join(' ')}" | tr ' ' '\n' ) \
        >> $csv_fn
    
    touch $plot_fn
    """
}

process compute_GoF {
    label 'analysis'

    container "${ params.container_python }"    
    debug true

    input:
        tuple val(model_id), val(cids), path(outfiles), val(model_dir), val(model_name), path(model_path), path(comp_path)
        path compile_config

    output:
        path "kolmogorov_smirnov.${model_dir}.${model_name}.csv", emit: runs_png

    script:
    def csv_fn = "runs.${model_id}.csv"
    def out_fn = "kolmogorov_smirnov.${model_dir}.${model_name}.csv"
    def out_desc_fn = "$model_path/output_description.csv"
    """
    echo "compile_id\tfile_name" >> $csv_fn
    paste -d "\t" \
        <(echo "${cids.join(' ')}"     | tr ' ' '\n' ) \
        <(echo "${outfiles.join(' ')}" | tr ' ' '\n' ) \
        >> $csv_fn
    
    goodness_of_fit.py $compile_config $csv_fn $out_desc_fn $comp_path $out_fn 
    """

    stub:
    def csv_fn = "runs.${model_id}.csv"
    def out_fn = "kolmogorov_smirnov.${model_dir}.${model_name}.csv"
    """
    echo "compile_id\tfile_name" >> $csv_fn
    paste -d "\t" \
        <(echo "${cids.join(' ')}"     | tr ' ' '\n' ) \
        <(echo "${outfiles.join(' ')}" | tr ' ' '\n' ) \
        >> $csv_fn
    
    touch $out_fn
    """
}


