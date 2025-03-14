import sys
import re

fn = sys.argv[1]
with open(fn) as fh:
    lines = fh.readlines()

patterns_and_subs = {
    r"assume (\w+) ~ (\w+\(.+\));": r"assume \1 ~ \2 drift \2;",
}

new_lines = []
for line in lines:
    new_line = line
    for p, s in patterns_and_subs.items():
        new_line = re.sub(p, s, new_line)
    new_lines.append(new_line)
with open("replaced_" + fn, "w") as fh:
    fh.writelines(new_lines)
