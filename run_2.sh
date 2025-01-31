az login

python agentless/fl/retrieve.py --index_type simple \
                                --filter_type given_files \
                                --filter_file "results/swe-bench-verified_${EXP_NAME}/file_level_irrelevant/loc_outputs.jsonl" \
                                --output_folder "results/swe-bench-verified_${EXP_NAME}/retrievel_embedding" \
                                --persist_dir embedding/swe-bench_simple \
                                --num_threads 2 \
                                --dataset=princeton-nlp/SWE-bench_Verified
