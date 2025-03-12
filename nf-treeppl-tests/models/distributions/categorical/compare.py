import numpy as np
import json
import sys

data_fn = sys.argv[1]
niter = int(sys.argv[2])
out_fn = sys.argv[3]

with open(data_fn) as fh:
    data_json = json.load(fh)

multinomial = np.random.multinomial(niter, data_json["params"])
categoricals = np.array([i for i, val in enumerate(multinomial) for _ in range(val)])
np.random.shuffle(categoricals)
with open(out_fn, "w") as fh:
    json.dump({"samples": {"x": categoricals.tolist()}}, fh)
