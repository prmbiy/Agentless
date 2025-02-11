set -e
EXP_NAME=r1

python agentless/fl/retrieve.py --index_type simple \
                                --filter_type given_files \
                                --filter_file "results/swe-bench-verified_${EXP_NAME}/file_level_irrelevant/loc_outputs.jsonl" \
                                --output_folder "results/swe-bench-verified_${EXP_NAME}/retrievel_embedding" \
                                --persist_dir embedding/swe-bench_simple \
                                --num_threads 4 \
                                --dataset=princeton-nlp/SWE-bench_Verified

python agentless/fl/combine.py  --retrieval_loc_file "results/swe-bench-verified_${EXP_NAME}/retrievel_embedding/retrieve_locs.jsonl" \
                                --model_loc_file "results/swe-bench-verified_${EXP_NAME}/file_level/loc_outputs.jsonl" \
                                --top_n 3 \
                                --output_folder "results/swe-bench-verified_${EXP_NAME}/file_level_combined"

python agentless/fl/localize.py --related_level \
                                --output_folder "results/swe-bench-verified_${EXP_NAME}/related_elements" \
                                --top_n 3 \
                                --compress_assign \
                                --compress \
                                --start_file "results/swe-bench-verified_${EXP_NAME}/file_level_combined/combined_locs.jsonl" \
                                --num_threads 1 \
                                --skip_existing \
                                --dataset=princeton-nlp/SWE-bench_Verified \
                                --model=deepseek-r1 \
                                --backend=deepseek-sgl

python agentless/fl/localize.py --fine_grain_line_level \
                                --output_folder "results/swe-bench-verified_${EXP_NAME}/edit_location_samples" \
                                --top_n 3 \
                                --compress \
                                --temperature 0.6 \
                                --num_samples 1 \
                                --start_file "results/swe-bench-verified_${EXP_NAME}/related_elements/loc_outputs.jsonl" \
                                --num_threads 1 \
                                --skip_existing \
                                --dataset=princeton-nlp/SWE-bench_Verified \
                                --model=deepseek-r1 \
                                --backend=deepseek-sgl

python agentless/fl/localize.py --merge \
                                --output_folder "results/swe-bench-verified_${EXP_NAME}/edit_location_individual" \
                                --top_n 3 \
                                --num_samples 1 \
                                --start_file "results/swe-bench-verified_${EXP_NAME}/edit_location_samples/loc_outputs.jsonl" \
                                --dataset=princeton-nlp/SWE-bench_Verified \
                                --model=deepseek-r1 \
                                --backend=deepseek-sgl

python agentless/repair/repair.py --loc_file "results/swe-bench-verified_${EXP_NAME}/edit_location_individual/loc_merged_0-0_outputs.jsonl" \
                                  --output_folder "results/swe-bench-verified_${EXP_NAME}/repair_sample_1" \
                                  --loc_interval \
                                  --top_n=3 \
                                  --context_window=10 \
                                  --max_samples 10  \
                                  --cot \
                                  --diff_format \
                                  --gen_and_process \
                                  --num_threads 1 \
                                  --dataset=princeton-nlp/SWE-bench_Verified \
                                  --model=deepseek-r1 \
                                  --backend=deepseek-sgl
