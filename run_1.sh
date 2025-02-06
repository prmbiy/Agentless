

python agentless/fl/localize.py --file_level \
                                --output_folder "results/swe-bench-verified_${EXP_NAME}/file_level" \
                                --num_threads 4 \
                                --skip_existing \
                                --dataset=princeton-nlp/SWE-bench_Verified \
                                --model=deepseek-reasoner \
                                --backend=deepseek

python agentless/fl/localize.py --file_level \
                                --irrelevant \
                                --output_folder "results/swe-bench-verified_${EXP_NAME}/file_level_irrelevant" \
                                --num_threads 3 \
                                --skip_existing \
                                --dataset=princeton-nlp/SWE-bench_Verified \
                                --model=deepseek-reasoner \
                                --backend=deepseek