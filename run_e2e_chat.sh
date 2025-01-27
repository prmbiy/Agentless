#!/bin/bash

python agentless/fl/localize.py --fine_grain_line_level \
                                --output_folder results/swe-bench-verified/edit_location_samples \
                                --top_n 3 \
                                --compress \
                                --temperature 0.8 \
                                --num_samples 4 \
                                --start_file results/swe-bench-verified/related_elements/loc_outputs.jsonl \
                                --num_threads 10 \
                                --skip_existing \
                                --dataset=princeton-nlp/SWE-bench_Verified \
                                --model=deepseek-reasoner \
                                --backend=deepseek

python agentless/fl/localize.py --merge \
                                --output_folder results/swe-bench-verified/edit_location_individual \
                                --top_n 3 \
                                --num_samples 4 \
                                --start_file results/swe-bench-verified/edit_location_samples/loc_outputs.jsonl \
                                --dataset=princeton-nlp/SWE-bench_Verified \
                                --model=deepseek-reasoner \
                                --backend=deepseek