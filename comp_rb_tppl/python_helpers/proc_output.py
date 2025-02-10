import pandas as pd
import numpy as np
import arviz as az
import xarray as xr
import json
import re
from functools import reduce
from pathlib import Path

pd.options.mode.chained_assignment = None


def get_outfiles(outdir: Path):
    # Define the regexes for the two types of filenames
    tppl_pattern = re.compile(r"output\.(\d+)\.(\d+)\.json")
    rb_pattern = re.compile(r"out\.(\d+)\.(\d+)\.log$")

    tppl_fns = []
    rb_fns = []
    for file in outdir.iterdir():
        fn = file.name

        # Check if the treeppl outfile name matches
        tppl_match = tppl_pattern.match(fn)
        if tppl_match is not None:
            genid, runid = tppl_match.groups(1)
            # Parse the outfile
            tppl_fns.append((int(genid), int(runid), file))
            continue

        # Check if the revbayes outfile name matches
        rb_match = rb_pattern.match(fn)
        if rb_match is not None:
            genid, runid = rb_match.groups(1)
            rb_fns.append((int(genid), int(runid), file))

    # Sort the files according to the generation id and the run id
    key = lambda x: (x[0], x[1])
    return sorted(tppl_fns, key=key), sorted(rb_fns, key=key)


def read_rb_file(file, rename=True):
    fn = file[2]
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
    return samples


def read_tppl_file(file):
    fn = file[2]
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
    return pd.DataFrame.from_dict(
        [extract_params(s["__data__"]) for s in parsed_file["samples"]]
    )


def inference_data_from_dataframe(df, chain=0, burnin=0):
    df.loc[:, "chain"] = chain
    df.loc[:, "draw"] = np.arange(len(df), dtype=int)
    df = df.set_index(["chain", "draw"])
    xdata = xr.Dataset.from_dataframe(df)
    return az.InferenceData(posterior=xdata)


def create_multi_chain_dataset(files, read_func, burnin):
    datasets = (
        inference_data_from_dataframe(read_func(fn), chain=i, burnin=burnin)
        for i, fn in enumerate(files)
    )
    concat = lambda x, y: az.concat(x, y, dim="chain")
    return reduce(concat, datasets)
