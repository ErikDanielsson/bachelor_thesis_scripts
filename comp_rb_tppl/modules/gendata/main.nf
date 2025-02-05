process generate_trees_and_interactions {
    publishDir "gen_data"

    input:
        val simid

    output:
        path "parasite_tree.${simid}.tre"
        path "host_tree.${simid}.tre"
        path "interactions.${simid}.csv"
        path "interactions.${simid}.nex"

    script:
    """
    Rscript $baseDir/scripts/generate_data.R ${simid}
    """
}

process rev_annotate_tree {
    publishDir "gen_data"

    input:
        val simid
        path input

    output:
        path "${input.getBaseName()}" + ".rev.tre"

    script:
    """
    rb $baseDir/scripts/annotate_tree.Rev --args ${input} --args ${input.baseName}.rev.tre
    """
}

process generate_phyjson {
    input:
        val simid
        path symbiont_tree_file
        path host_tree_file
        path interactions_csv_file

    output:
        path "dirty_host_parasite${simid}.json"
    
    script:
    """
    Rscript $baseDir/scripts/transform_data_to_phyjson.R ${symbiont_tree_file} ${host_tree_file} ${interactions_csv_file} "dirty_host_parasite${simid}.json"
    """
}

process clean_phyjson {
    publishDir "gen_data"

    input:
        val simid
        path dirty_phyjson

    output:
        path "host_parasite${simid}.json"

    script:
    """
    python $baseDir/scripts/clean_phyjson.py ${dirty_phyjson} "host_parasite${simid}.json"
    """
}