#!/bin/bash

# Common parameters
TARGET_ID=$1
DATASET=$2
MODEL=$3
BACKEND=$4
NUM_THREADS=$5
NUM_WORKERS=$6

# Output directories
OUTPUT_ROOT="results/swe-bench-verified"

# Ensure required parameters are provided
if [ $# -lt 6 ]; then
    echo "Usage: $0 <target_id> <dataset> <model> <backend> <num_threads> <num_workers>"
    exit 1
fi

# echo "Starting workflow with target_id=${TARGET_ID}, dataset=${DATASET}"

# Step L.1
python agentless/fl/localize.py --file_level \
    --output_folder "${OUTPUT_ROOT}/file_level" \
    --num_threads "$NUM_THREADS" \
    --skip_existing \
    --dataset="$DATASET" \
    --model="$MODEL" \
    --backend="$BACKEND" 
    # --target_id="$TARGET_ID"

python agentless/fl/localize.py --file_level --irrelevant \
    --output_folder "${OUTPUT_ROOT}/file_level_irrelevant" \
    --num_threads "$NUM_THREADS" \
    --skip_existing \
    --dataset="$DATASET" \
    --model="$MODEL" \
    --backend="$BACKEND" 
    # --target_id="$TARGET_ID"

python agentless/fl/retrieve.py --index_type simple \
    --filter_type given_files \
    --filter_file "${OUTPUT_ROOT}/file_level_irrelevant/loc_outputs.jsonl" \
    --output_folder "${OUTPUT_ROOT}/retrievel_embedding" \
    --persist_dir embedding/swe-bench_simple \
    --num_threads "$NUM_THREADS" \
    --dataset="$DATASET"
    # --target_id="$TARGET_ID" \

python agentless/fl/combine.py --retrieval_loc_file "${OUTPUT_ROOT}/retrievel_embedding/retrieve_locs.jsonl" \
    --model_loc_file "${OUTPUT_ROOT}/file_level/loc_outputs.jsonl" \
    --top_n 3 \
    --output_folder "${OUTPUT_ROOT}/file_level_combined"

# Step L.2
python agentless/fl/localize.py --related_level \
    --output_folder "${OUTPUT_ROOT}/related_elements" \
    --top_n 3 \
    --compress_assign \
    --compress \
    --start_file "${OUTPUT_ROOT}/file_level_combined/combined_locs.jsonl" \
    --num_threads "$NUM_THREADS" \
    --skip_existing \
    --dataset="$DATASET" \
    --model="$MODEL" \
    --backend="$BACKEND" 
    # --target_id="$TARGET_ID"

# Step L.3
python agentless/fl/localize.py --fine_grain_line_level \
    --output_folder "${OUTPUT_ROOT}/edit_location_samples" \
    --top_n 3 \
    --compress \
    --temperature 0.8 \
    --num_samples 4 \
    --start_file "${OUTPUT_ROOT}/related_elements/loc_outputs.jsonl" \
    --num_threads "$NUM_THREADS" \
    --skip_existing \
    --dataset="$DATASET" \
    --model="$MODEL" \
    --backend="$BACKEND" 
    # --target_id="$TARGET_ID"

python agentless/fl/localize.py --merge \
    --output_folder "${OUTPUT_ROOT}/edit_location_individual" \
    --top_n 3 \
    --num_samples 4 \
    --start_file "${OUTPUT_ROOT}/edit_location_samples/loc_outputs.jsonl" \
    --dataset="$DATASET" \
    --model="$MODEL" \
    --backend="$BACKEND" 
    # --target_id="$TARGET_ID"

# Step R.1
# for i in {0..3}; do
python agentless/repair/repair.py --loc_file "${OUTPUT_ROOT}/edit_location_individual/loc_merged_0-0_outputs.jsonl" \
    --output_folder "${OUTPUT_ROOT}/repair_sample_1" \
    --loc_interval \
    --top_n=3 \
    --context_window=10 \
    --max_samples 10 \
    --cot \
    --diff_format \
    --gen_and_process \
    --num_threads 2 \
    --dataset="$DATASET" \
    --model="$MODEL" \
    --backend="$BACKEND" 
    # --target_id="$TARGET_ID"
# done

# Step V.1 to V.7
python agentless/test/run_regression_tests.py --run_id generate_regression_tests \
    --output_file "${OUTPUT_ROOT}/passing_tests.jsonl" \
    --dataset="$DATASET"
    # --instance_ids="$TARGET_ID" \

python agentless/test/select_regression_tests.py --passing_tests "${OUTPUT_ROOT}/passing_tests.jsonl" \
    --output_folder "${OUTPUT_ROOT}/select_regression" \
    --dataset="$DATASET" \
    --model="$MODEL" \
    --backend="$BACKEND" \
    # --instance_ids="$TARGET_ID" \
    # --target_id="$TARGET_ID"

FOLDER="${OUTPUT_ROOT}/repair_sample_1"
for NUM in {0..9}; do
    RUN_ID_PREFIX=$(basename "$FOLDER")
    python agentless/test/run_regression_tests.py --regression_tests "${OUTPUT_ROOT}/select_regression/output.jsonl" \
        --predictions_path="${FOLDER}/output_${NUM}_processed.jsonl" \
        --run_id="${RUN_ID_PREFIX}_regression_${NUM}" \
        --num_workers "$NUM_WORKERS" \
        --dataset="$DATASET"
        # --instance_ids="$TARGET_ID" \
done

python agentless/test/generate_reproduction_tests.py --max_samples 40 \
    --output_folder "${OUTPUT_ROOT}/reproduction_test_samples" \
    --num_threads "$NUM_THREADS" \
    --dataset="$DATASET" \
    --model="$MODEL" \
    --backend="$BACKEND"
    # --target_id="$TARGET_ID" \

for ST in {0..36..4}; do
    EN=$((ST + 3))
    echo "Processing ${ST} to ${EN}"
    for NUM in $(seq "$ST" "$EN"); do
        echo "Processing ${NUM}"
        python agentless/test/run_reproduction_tests.py --run_id="reproduction_test_generation_filter_sample_${NUM}" \
            --test_jsonl="${OUTPUT_ROOT}/reproduction_test_samples/output_${NUM}_processed_reproduction_test.jsonl" \
            --num_workers "$NUM_WORKERS" \
            --testing \
            --dataset="$DATASET"
            # --instance_ids="$TARGET_ID" \
    done
done

python agentless/test/generate_reproduction_tests.py --max_samples 40 \
    --output_folder "${OUTPUT_ROOT}/reproduction_test_samples" \
    --output_file reproduction_tests.jsonl \
    --select \
    --dataset="$DATASET" \
    --model="$MODEL" \
    --backend="$BACKEND"
    # --target_id="$TARGET_ID" \

for NUM in {0..9}; do
    RUN_ID_PREFIX=$(basename "$FOLDER")
    python agentless/test/run_reproduction_tests.py --test_jsonl "${OUTPUT_ROOT}/reproduction_test_samples/reproduction_tests.jsonl" \
        --predictions_path="${FOLDER}/output_${NUM}_processed.jsonl" \
        --run_id="${RUN_ID_PREFIX}_reproduction_${NUM}" \
        --num_workers "$NUM_WORKERS" \
        --dataset="$DATASET"
        # --instance_ids="$TARGET_ID" \
done

python agentless/repair/rerank.py --patch_folder "${OUTPUT_ROOT}/repair_sample_1/" \
    --output_file "${OUTPUT_ROOT}/all_preds.jsonl" \
    --num_samples 10 \
    --deduplicate \
    --regression \
    --reproduction

echo "Workflow completed successfully!"
