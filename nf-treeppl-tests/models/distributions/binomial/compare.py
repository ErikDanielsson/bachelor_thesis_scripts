import numpy as np
import json
import sys

data_fn = sys.argv[1]
niter = int(sys.argv[2])
out_fn = sys.argv[3]

with open(data_fn) as fh:
    data_json = json.load(fh)

binomials = np.random.binomial(data_json["n"], data_json["p"], niter)
with open(out_fn, "w") as fh:
    json.dump({"samples": {"x": binomials.tolist()}}, fh)
