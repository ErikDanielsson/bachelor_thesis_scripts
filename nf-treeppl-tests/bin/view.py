import json
import seaborn as sns
import matplotlib.pyplot as plt
import sys


def read_samples(fn):
    with open(fn) as fh:
        cont = json.load(fh)
    return cont["samples"]


def view(samples):
    return sns.histplot(x=samples)


def main():
    fn = sys.argv[1]
    samples = read_samples(fn)
    plot = view(samples)
    return plt.show()


main()
