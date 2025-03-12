import numpy as np
import json
import sys

data_fn = sys.argv[1]
niter = int(sys.argv[2])
out_fn = sys.argv[3]

with open(data_fn) as fh:
    data_json = json.load(fh)

# Python parametrizes the exponential with the mean rather than the rate
exponentials = np.random.exponential(1 / data_json["b"], niter)
with open(out_fn, "w") as fh:
    json.dump({"samples": {"x": exponentials.tolist()}}, fh)
