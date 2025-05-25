#!/bin/bash

#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --export=ALL
#SBATCH --job-name="compressed"
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH --nodes=1
#SBATCH --output="compressed.%j.%N.out"
#SBATCH -t 06:00:00

module load StdEnv/2020
module load cmake
module load gcc
module load python
module load cuda/12.2

cd ASpT_SpMM_GPU
nvcc -std=c++11 -O3 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_53,code=sm_53 sspmm_32.cu --use_fast_math -Xptxas "-v -dlcm=ca" -o sspmm_32
nvcc -std=c++11 -O3 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_53,code=sm_53 sspmm_128.cu --use_fast_math -Xptxas "-v -dlcm=ca" -o sspmm_128
nvcc -std=c++11 -O3 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_53,code=sm_53 dspmm_32.cu --use_fast_math -Xptxas "-v -dlcm=ca" -o dspmm_32
nvcc -std=c++11 -O3 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_80,code=sm_80 -gencode arch=compute_53,code=sm_53 dspmm_128.cu --use_fast_math -Xptxas "-v -dlcm=ca" -o dspmm_128
cd ..

