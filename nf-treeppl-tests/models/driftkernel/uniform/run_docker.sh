#! /bin/bash
model_dir=$1
seed=$2
niter=$3
flag="-m mcmc-lightweight --cps full --align --kernel --debug-phases"
docker run --rm -v $PWD/$model_dir:/$model_dir danielssonerik/treeppl:custom-drift-kernels \
    /bin/bash -c "tpplc /$model_dir/model.tppl --seed $seed $flag; ./out /$model_dir/data.json $niter" 
