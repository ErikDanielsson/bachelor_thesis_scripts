#! /usr/bin/env python
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd
import sys
import helpers


def plot_single(ax, samples, title):
    sns.histplot(x=samples, ax=ax)
    ax.set_title(f"{title}")
    return ax


def main(compile_config_fn, runs_fn, comp_path_fn, out_fn_prefix):
    tot_df = helpers.get_model_df(compile_config_fn, runs_fn)
    variables_and_types = helpers.get_output_desc(out_desc_fn)
    n_plots = len(tot_df.index) + 1
    rows = max(int(np.ceil(np.sqrt(n_plots))), 2)
    cols = max(int(np.ceil(n_plots / rows)), 2)
    for variable, _ in variables_and_types.items():
        fig, axs = plt.subplots(rows, cols)
        comp_samples = helpers.get_compare_samples(comp_path_fn, variable)
        plot_single(axs[0, 0], comp_samples, "Python comparision")
        ind1, ind2 = np.unravel_index(range(1, n_plots), (rows, cols))
        for i, ix, iy in zip(range(n_plots - 1), ind1, ind2):
            ax = axs[ix, iy]
            json_fn = tot_df.loc[i, "file_name"]
            algorithm = tot_df.loc[i, "m"]
            samples = helpers.get_samples(json_fn, variable)
            plot_single(ax, samples, algorithm)
        fig.suptitle(f"Variable {variable}")
        fig.tight_layout()
        fig.savefig(f"{out_fn_prefix}.{variable}.png")


if __name__ == "__main__":
    compile_config_fn = sys.argv[1]
    runs_fn = sys.argv[2]
    out_desc_fn = sys.argv[3]
    comp_path_fn = sys.argv[4]
    out_fn = sys.argv[5]
    main(compile_config_fn, runs_fn, comp_path_fn, out_fn)
