#!/bin/bash

#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --export=ALL
#SBATCH --job-name="compressed_dlmc" # Changed job name slightly
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH --nodes=1
#SBATCH --output="compressed_dlmc.%j.%N.out" # Changed output file name
#SBATCH -t 06:00:00

module load StdEnv/2020
module load cmake
module load gcc
module load python
module load cuda/12.2

if [ -z "$1" ]; then
  echo "Usage: $0 <matrix_list_file>"
  exit 1
fi
MATRIX_LIST_FILE=$1
BASEPATH=$2

mkdir -p GPU_SpMM_dlmc_result # Ensure directory exists

# Initialize main output files with headers
echo "dataset,ASpT_GFLOPs(K=4),ASpT_diff_%%(K=4),ASpT_GFLOPs(K=8),ASpT_diff_%%(K=8),ASpT_GFLOPs(K=32),ASpT_diff_%%(K=32),ASpT_GFLOPs(K=128),ASpT_diff_%%(K=128)" > SpMM_GPU_SP.out

# Single Precision Loop
while read -r mtx_file_path; do
  if [ -z "$mtx_file_path" ]; then # Skip empty lines
    continue
  fi
  path="${BASEPATH}/${mtx_file_path}"
  echo -n "$path," >> SpMM_GPU_SP.out # Write matrix name, start of new line
  ./ASpT_SpMM_GPU/dspmm_32 "$path" 4 # Appends GFLOPs,diff_%,
  ./ASpT_SpMM_GPU/dspmm_32 "$path" 8 # Appends GFLOPs,diff_%,
  ./ASpT_SpMM_GPU/dspmm_32 "$path" 32 # Appends GFLOPs,diff_%,
  ./ASpT_SpMM_GPU/sspmm_128 "$path" 128 # Appends GFLOPs,diff_%,
  sed -i '$ s/,$//' SpMM_GPU_SP.out # Remove the last comma from the line just written
  echo >> SpMM_GPU_SP.out # Add a newline to complete the line
done < "$MATRIX_LIST_FILE"

# Finalize and Cleanup
mv SpMM_GPU_SP.out GPU_SpMM_dlmc_result/SpMM_GPU_SP_dlmc.out
mv SpMM_GPU_DP.out GPU_SpMM_dlmc_result/SpMM_GPU_DP_dlmc.out
rm -f SpMM_GPU_SP_preprocessing.out SpMM_GPU_DP_preprocessing.out # Remove preprocessing files
rm -f gmon.out
