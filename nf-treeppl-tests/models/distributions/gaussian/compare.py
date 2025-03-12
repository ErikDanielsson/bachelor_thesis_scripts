import numpy as np
import json
import sys

data_fn = sys.argv[1]
niter = int(sys.argv[2])
out_fn = sys.argv[3]

with open(data_fn) as fh:
    data_json = json.load(fh)

normals = np.random.normal(data_json["mean"], data_json["std"], niter)
with open(out_fn, "w") as fh:
    json.dump({"samples": {"x": normals.tolist()}}, fh)
