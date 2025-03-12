#! /usr/bin/env python

import scipy.stats as stats
import numpy as np
import pandas as pd
import helpers
import sys


def ks_statistic(samp1, samp2, index):
    ks_res = stats.ks_2samp(samp1, samp2)
    return pd.Series(
        [ks_res.statistic, ks_res.pvalue],
        index=index,
    )


def chi2_statistic(samp1, samp2, index):
    # We assume that the samples have equal lengths
    samp1 = np.array(samp1)
    samp2 = np.array(samp2)
    cats = set(samp1).union(samp2)
    freqs1 = np.array([np.sum(samp1 == c) for c in cats])
    freqs2 = np.array([np.sum(samp2 == c) for c in cats])
    cont_tab = np.array([freqs1, freqs2]).T
    chi2_res = stats.contingency.chi2_contingency(cont_tab)
    return pd.Series(
        [chi2_res.statistic, chi2_res.pvalue],
        index=index,
    )


def main(compile_config_fn, runs_fn, out_desc_fn, compare_fn, out_fn):
    tot_df = helpers.get_model_df(compile_config_fn, runs_fn)
    variables_and_types = helpers.get_output_desc(out_desc_fn)

    statistic_cols = []
    for variable, dtype in variables_and_types.items():
        comp_samples = helpers.get_compare_samples(compare_fn, variable)
        if dtype == "continuous":
            cols = [f"{variable}.ks_statistic", f"{variable}.ks_pval"]
            statistic_cols.extend(cols)
            tot_df.loc[:, cols] = tot_df.loc[:, "file_name"].apply(
                (
                    lambda fn: ks_statistic(
                        helpers.get_samples(fn, variable),
                        comp_samples,
                        cols,
                    )
                )
            )
        elif dtype == "discrete":
            cols = [f"{variable}.chi2_statistic", f"{variable}.chi2_pval"]
            statistic_cols.extend(cols)
            tot_df.loc[:, cols] = tot_df.loc[:, "file_name"].apply(
                (
                    lambda fn: chi2_statistic(
                        helpers.get_samples(fn, variable),
                        comp_samples,
                        cols,
                    )
                )
            )
        tot_df.loc[:, ["compile_id", "runid", "m"] + statistic_cols].to_csv(
            out_fn, sep="\t"
        )


if __name__ == "__main__":
    compile_config_fn = sys.argv[1]
    runs_fn = sys.argv[2]
    out_desc_fn = sys.argv[3]
    comp_path_fn = sys.argv[4]
    out_fn = sys.argv[5]
    main(compile_config_fn, runs_fn, out_desc_fn, comp_path_fn, out_fn)
