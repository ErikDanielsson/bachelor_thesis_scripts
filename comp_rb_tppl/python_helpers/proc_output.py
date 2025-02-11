import pandas as pd
import numpy as np
import arviz as az
import xarray as xr
import matplotlib.pyplot as plt
import json
import re
import os
from functools import reduce
from pathlib import Path

pd.options.mode.chained_assignment = None


def get_temp_dir():
    temp_dir = Path(os.getcwd()) / "qmd_temp"
    if not temp_dir.exists():
        temp_dir.mkdir()
    return temp_dir


def get_temp_file(fn):
    return get_temp_dir() / (Path(fn).stem + ".csv")


def get_files_in_dir(dir: Path, patterns: dict[str, re.Pattern]):
    fns = {k: {} for k in patterns}
    for file in dir.iterdir():
        fn = file.name
        for k, pattern in patterns.items():
            m = pattern.match(fn)
            if m is not None:
                genid, runid = m.groups(1)
                genid, runid = int(genid), int(runid)
                if genid not in fns[k]:
                    fns[k][genid] = {}
                fns[k][genid][runid] = file
    return fns


def get_outfiles(outdir: Path):
    # Define the regexes for the two types of filenames
    tppl_pattern = re.compile(r"output\.(\d+)\.(\d+)\.json")
    rb_pattern = re.compile(r"out\.(\d+)\.(\d+)\.log$")

    tppl_fns = {}
    rb_fns = {}
    for file in outdir.iterdir():
        fn = file.name

        # Check if the treeppl outfile name matches
        tppl_match = tppl_pattern.match(fn)
        if tppl_match is not None:
            genid, runid = tppl_match.groups(1)
            genid, runid = int(genid), int(runid)
            # Parse the outfile
            if genid not in tppl_fns:
                tppl_fns[genid] = {}
            tppl_fns[genid][runid] = file
            continue

        # Check if the revbayes outfile name matches
        rb_match = rb_pattern.match(fn)
        if rb_match is not None:
            genid, runid = rb_match.groups(1)
            genid, runid = int(genid), int(runid)
            if genid not in rb_fns:
                rb_fns[genid] = {}
            rb_fns[genid][runid] = file

    return tppl_fns, rb_fns


def read_rb_file(fn, rename=True, with_file=True):
    if with_file:
        temp_fn = get_temp_file(fn)
        if temp_fn.exists():
            return pd.read_csv(temp_fn, index_col=0)
    samples = pd.read_csv(fn, sep="\t")
    if rename:
        # Just use the columns we are interested in
        samples = samples[
            [
                "clock_host",
                "phy_scale[1]",
                "switch_rate_0_to_1",
                "switch_rate_1_to_0",
                "switch_rate_1_to_2",
                "switch_rate_2_to_1",
            ]
        ]
        # Rename them
        name_map = {
            "clock_host": "mu",
            "phy_scale[1]": "beta",
            "switch_rate_0_to_1": "lambda_01",
            "switch_rate_1_to_0": "lambda_10",
            "switch_rate_1_to_2": "lambda_12",
            "switch_rate_2_to_1": "lambda_21",
        }
        samples = samples.rename(columns=name_map)
    if with_file:
        samples.to_csv(temp_fn)
    return samples


def read_tppl_file(fn, with_file=True):
    if with_file:
        temp_fn = get_temp_dir() / (Path(fn).stem + ".csv")
        if temp_fn.exists():
            return pd.read_csv(temp_fn, index_col=0)
    with open(fn) as fh:
        parsed_file = json.load(fh)
    rename_lambda = [
        "lambda_01",
        "lambda_10",
        "lambda_12",
        "lambda_21",
    ]

    def extract_params(data_entry):
        # Remove the tree
        data_entry.pop("tree")

        # Flatten the lambda entry
        for i, lambda_val in enumerate(data_entry["lambda"]):
            data_entry[rename_lambda[i]] = lambda_val
        data_entry.pop("lambda")

        return data_entry

    # Process the samples, and remove unnecessary params
    df = pd.DataFrame.from_dict(
        [extract_params(s["__data__"]) for s in parsed_file["samples"]]
    )
    if with_file:
        df.to_csv(temp_fn)

    return df


def inference_data_from_dataframe(df, chain=0, burnin=0, subsample=1):
    index = df.index[burnin::subsample]
    df = df.iloc[index, :]
    df.loc[:, "chain"] = chain
    df.loc[:, "draw"] = index
    df = df.set_index(["chain", "draw"])
    xdata = xr.Dataset.from_dataframe(df)
    return az.InferenceData(posterior=xdata)


def create_inference_data(files, read_func, burnin, subsample=1):
    datasets = {
        genid: {
            runid: inference_data_from_dataframe(
                read_func(fn),
                chain=hash((genid, runid)),
                burnin=burnin,
                subsample=subsample,
            )
            for runid, fn in runs.items()
        }
        for genid, runs in files.items()
    }
    return datasets


def create_multi_chain_dataset(inference_datas, type="genid"):
    concat = lambda x, y: az.concat(x, y, dim="chain")
    if type == "all":
        return reduce(
            concat,
            (
                data
                for genid, run_datas in inference_datas.items()
                for runid, data in run_datas.items()
            ),
        )
    if type == "genid":
        return {
            genid: reduce(concat, run_datas.values())
            for genid, run_datas in inference_datas.items()
        }


def calc_ess_all(datas):
    def xarray_to_dict(xarray):
        data_vars = xarray.to_dict()["data_vars"]
        return {k: v["data"] for k, v in data_vars.items()}

    esses = {
        (genid, runid): xarray_to_dict(az.ess(data, method="mean"))
        for genid, run_datas in datas.items()
        for runid, data in run_datas.items()
    }
    df = pd.DataFrame.from_dict(esses, orient="index")
    return df


def ess_bar_plot(
    ess_df: pd.DataFrame, fig=None, axs=None, c="b", label=None, width=0.9, mv=0.0
):
    n_gen = len(ess_df.index.levels[0])
    n_runs = len(ess_df.index.levels[1])
    if fig is None or axs is None:
        fig, axs = plt.subplots(n_gen, 1)
    ess_df_avg = ess_df.groupby(level=0).mean()
    for i, genid in enumerate(ess_df_avg.index):
        ax = axs[i]
        ax.bar(
            np.arange(len(ess_df_avg.columns)) + mv,
            ess_df_avg.loc[genid, :],
            color=c,
            width=width,
            label=label,
        )
        ax.set_ylabel(f"Genid {genid}")
        ax.set_xticks(range(len(ess_df_avg.columns)), ess_df_avg.columns.to_list())
        ax.legend()
        # ax.set_xticks(ess_df_avg.columns)
    fig.suptitle(f"Average ESS over {n_runs} runs")
    return fig, axs


def ess_box_plot(ess_df):
    n_vars = len(ess_df.columns)
    n_gen = len(ess_df.index.levels[0])
    fig, axs = plt.subplots(n_gen, n_vars)
    for i, genid in enumerate(ess_df.index.levels[0]):
        for j, var_name in enumerate(ess_df.columns):
            ax = axs[i, j]
            ax.boxplot(ess_df.xs(genid, level=0)[var_name])
    return fig, axs


def get_time_files(outdir: Path):
    # Define the regexes for the two types of filenames
    tppl_pattern = re.compile(r"time\.treeppl\.(\d+)\.(\d+)\.txt")
    rb_pattern = re.compile(r"time\.revbayes\.(\d+)\.(\d+)\.txt")

    fns = get_files_in_dir(outdir, {"tppl": tppl_pattern, "rb": rb_pattern})

    return fns["tppl"], fns["rb"]


def parse_time_files(time_files):
    return {
        genid: {runid: proc_time_txt(fn) for runid, fn in run_files.items()}
        for genid, run_files in time_files.items()
    }


def proc_time_txt(fn, type="user"):

    def parse_time_str(time_str):
        """
        Extremely hacky parser for the Swedish time
        string format from bash's time command
        """
        pattern = re.compile(r"(\d+)m(\d+),(\d+)s")
        match = pattern.findall(time_str)
        if len(match) == 0:
            raise Exception("Could not parse time str")
        minutes, sec, frac = match[0]
        return int(minutes) * 60 + int(sec) + int(frac) * 10 ** (-len(frac))

    time_df = pd.read_csv(fn, sep="\t", names=["time"], index_col=0)
    time_dict = time_df.to_dict()["time"]
    time_dict = {type: parse_time_str(time_str) for type, time_str in time_dict.items()}
    return time_dict[type]
