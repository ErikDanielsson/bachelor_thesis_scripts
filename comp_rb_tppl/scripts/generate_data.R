#### Small simulated dataset to compare TreePPL and RevBayes ####

library(tidyverse)
library(ape)
library(ggtree)
library(evolnets)
library(treepplr)

args = commandArgs(trailingOnly=TRUE)

tree <- rcoal(4, rooted = TRUE)
tree$tip.label <- paste0("S", 1:4)

height <- node.depth.edgelength(tree)[1]
scaling_factor <- 2.0/height
tree$edge.length <- tree$edge.length*scaling_factor

is.binary(tree)
is.ultrametric(tree)
is.rooted(tree)

host_tree <- rcoal(3, rooted = TRUE)
host_tree$tip.label <- paste0("H", 1:3)

# Create interaction matrix
matrix <- matrix(data = c(2,0,2, 2,0,0, 2,2,0, 0,2,0), nrow = 4, ncol = 3, byrow = TRUE)
print(matrix)
rownames(matrix) <- tree$tip.label
colnames(matrix) <- host_tree$tip.label

# Write output files
interaction_csv_fn = paste0("interactions.", args[1], ".csv")
interaction_nex_fn = paste0("interactions.", args[1], ".nex")
host_tree_fn = paste0("host_tree.", args[1], ".tre")
parasite_tree_fn = paste0("parasite_tree.", args[1], ".tre")
write.csv(matrix, interaction_csv_fn, row.names = TRUE)
write.nexus.data(matrix, interaction_nex_fn, format = "standard")
write.tree(host_tree, host_tree_fn)
write.tree(tree, parasite_tree_fn)

# Add subroot branch to tree
tree_string <- readLines(parasite_tree_fn)
tree_tiny_stem_string <- sub(");$", "):0.01;", tree_string)
tiny_tree_fn = paste0("tiny_stem_tree.", args[1], ".tre")
writeLines(tree_tiny_stem_string, tiny_tree_fn)
tree_long_stem_string <- sub(");$", "):2.0;", tree_string)
long_tree_fn = paste0("long_stem_tree.", args[1], ".tre")
writeLines(tree_long_stem_string, long_tree_fn)
