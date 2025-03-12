import numpy as np
import json
import sys

data_fn = sys.argv[1]
niter = int(sys.argv[2])
out_fn = sys.argv[3]

with open(data_fn) as fh:
    data_json = json.load(fh)

poissons = np.random.poisson(data_json["rate"], niter)
with open(out_fn, "w") as fh:
    json.dump({"samples": {"x": poissons.tolist()}}, fh)
