#!/bin/bash

#SBATCH --gpus-per-node=1
#SBATCH --export=ALL
#SBATCH --job-name="compressed_dlmc"
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH --nodes=1
#SBATCH --mem=32G               # ← Request more memory explicitly
#SBATCH --output="compressed_dlmc.%j.%N.out"
#SBATCH -t 24:00:00

set -euo pipefail               # ← Safer script execution

module load StdEnv/2020
module load cmake
module load gcc
module load python
module load cuda/12.2

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <matrix_list_file> <base_path>"
  exit 1
fi

MATRIX_LIST_FILE=$1
BASEPATH=$2

mkdir -p GPU_SpMM_dlmc_result

echo "dataset,ASpT_GFLOPs(K=32),ASpT_diff_%%(K=32),ASpT_GFLOPs(K=128),ASpT_diff_%%(K=128)" > SpMM_GPU_SP.out

echo "Starting run at $(date)"
nvidia-smi

while read -r mtx_file_path; do
  if [ -z "$mtx_file_path" ]; then continue; fi

  path="${BASEPATH}${mtx_file_path}"
  echo "Processing: $path"

  echo -n "$path," >> SpMM_GPU_SP.out

  # Run one binary at a time to avoid memory overflow
  ./ASpT_SpMM_GPU/sspmm_32 "$path" 32 || echo "FAILED dspmm_32 $path" >> errors.log
  sleep 1

  ./ASpT_SpMM_GPU/sspmm_128 "$path" 128 || echo "FAILED sspmm_128 $path" >> errors.log
  sleep 1

  sed -i '$ s/,$//' SpMM_GPU_SP.out
  echo >> SpMM_GPU_SP.out

  echo "Finished: $path"
done < "$MATRIX_LIST_FILE"

mv SpMM_GPU_SP.out GPU_SpMM_dlmc_result/SpMM_GPU_SP_dlmc.out

# Only move DP file if it exists
[ -f SpMM_GPU_DP.out ] && mv SpMM_GPU_DP.out GPU_SpMM_dlmc_result/SpMM_GPU_DP_dlmc.out

rm -f SpMM_GPU_SP_preprocessing.out SpMM_GPU_DP_preprocessing.out gmon.out

echo "All done at $(date)"
