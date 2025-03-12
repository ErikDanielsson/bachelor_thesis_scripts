#! /usr/bin/env python
import numpy as np
import pandas as pd
import json
import re
import shlex


def parse_compile_params(
    fn,
    header=["compile_id", "runid", "model_id", "model_path", "alg_type", "flags"],
    dtypes=[int, int, int, str, str, str],
    parse_flags=True,
):
    df = pd.read_csv(
        fn,
        names=header,
        sep="\t",
        index_col=False,
        dtype={h: d for h, d in zip(header, dtypes)},
    )
    if parse_flags:
        flag_df = parse_sim_flags(df)
        return pd.concat([df, flag_df], axis=1).drop(columns=["flags"])
    return df


def parse_sim_flags(df, flag_col="flags"):
    return df[flag_col].apply(parse_cmd_line_flag).apply(pd.Series)


def parse_cmd_line_flag(flag):
    flag_pattern = re.compile(r"--?([\w-]+)")  # Matches the flags
    split_flag = shlex.split(flag)
    flag_idx = [flag_pattern.match(arg_part) for arg_part in split_flag]
    args = {}
    i = 0
    while i < len(split_flag):
        if flag_idx[i]:
            flag_name = flag_idx[i].group(1)
            i += 1
            if i < len(split_flag) and not flag_idx[i]:
                args[flag_name] = split_flag[i]
                i += 1
            else:
                args[flag_name] = True
        else:
            print(split_flag[i])
            i += 1
    return args


def get_compare_samples(json_fn, variable):
    with open(json_fn) as fh:
        cont = json.load(fh)
    return cont["samples"][variable]


def get_samples(json_fn, variable):
    with open(json_fn) as fh:
        cont = json.load(fh)
    samples = cont["samples"]
    return [s["__data__"][variable] for s in samples]


def get_output_desc(out_desc_fn):
    df = pd.read_csv(out_desc_fn)
    return dict(zip(df["variable"], df["data_type"]))


def get_model_df(compile_config_fn, treeppl_runs_fn):
    compile_config_df = parse_compile_params(compile_config_fn)
    runs_df = pd.read_csv(treeppl_runs_fn, sep="\t")
    return runs_df.merge(compile_config_df, on="compile_id", how="left")
