import numpy as np
import json
import sys

data_fn = sys.argv[1]
niter = int(sys.argv[2])
out_fn = sys.argv[3]

with open(data_fn) as fh:
    data_json = json.load(fh)

obs = data_json["observations"]
prior_alpha = data_json["a"]
prior_beta = data_json["b"]
N = len(obs)
succ = sum(obs)
# The prior is Beta(1, 1) so the posterior is
new_alpha = succ + prior_alpha
new_beta = N - succ + prior_beta
ps = np.random.beta(new_alpha, new_beta, niter)
with open(out_fn, "w") as fh:
    json.dump({"samples": {"p": ps.tolist()}}, fh)
