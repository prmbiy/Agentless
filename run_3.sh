set -e
EXP_NAME="r1"

python agentless/test/run_regression_tests.py --run_id generate_regression_tests \
    --num_workers 1 \
    --output_file results/swe-bench-verified_${EXP_NAME}/passing_tests.jsonl \
    --dataset=princeton-nlp/SWE-bench_Verified

python agentless/test/select_regression_tests.py --passing_tests results/swe-bench-verified_${EXP_NAME}/passing_tests.jsonl \
    --output_folder results/swe-bench-verified_${EXP_NAME}/select_regression \
    --dataset=princeton-nlp/SWE-bench_Verified \
    --model=deepseek-r1 \
    --backend=deepseek-sgl

folder=results/swe-bench-verified_${EXP_NAME}/repair_sample_1
for num in {0..9..1}; do
    run_id_prefix=$(basename $folder); 
    python agentless/test/run_regression_tests.py --regression_tests results/swe-bench-verified_${EXP_NAME}/select_regression/output.jsonl \
    --predictions_path="${folder}/output_${num}_processed.jsonl" \
    --run_id="${run_id_prefix}_regression_${num}" \
    --num_workers 4 \
    --dataset=princeton-nlp/SWE-bench_Verified;
done

python agentless/test/generate_reproduction_tests.py --max_samples 10 \
    --output_folder results/swe-bench-verified_${EXP_NAME}/reproduction_test_samples \
    --num_threads 1 \
    --dataset=princeton-nlp/SWE-bench_Verified \
    --model=deepseek-r1 \
    --backend=deepseek-sgl

for num in {0..9}; do
    echo "Processing ${num}";
    python agentless/test/run_reproduction_tests.py --run_id="reproduction_test_generation_filter_sample_${num}" \
    --test_jsonl="results/swe-bench-verified_${EXP_NAME}/reproduction_test_samples/output_${num}_processed_reproduction_test.jsonl" \
    --num_workers 4 \
    --testing \
    --dataset=princeton-nlp/SWE-bench_Verified & 
done
wait

python agentless/test/run_reproduction_tests.py --run_id="reproduction_test_generation_filter_sample_0" \
    --test_jsonl="results/swe-bench-verified_${EXP_NAME}/reproduction_test_samples/output_0_processed_reproduction_test.jsonl" \
    --num_workers 4 \
    --testing \
    --dataset=princeton-nlp/SWE-bench_Verified & 

for st in {0..36..4}; do   en=$((st + 3));   
        echo "Processing ${st} to ${en}";   
        for num in $(seq $st $en); do     
            echo "Processing ${num}";     
            python agentless/test/run_reproduction_tests.py --run_id="reproduction_test_generation_filter_sample_${num}" \
                --test_jsonl="results/swe-bench-verified_${EXP_NAME}/reproduction_test_samples/output_${num}_processed_reproduction_test.jsonl" \
                --num_workers 6 \
                --testing \
                --dataset=princeton-nlp/SWE-bench_Verified;
done & done

python agentless/test/generate_reproduction_tests.py --max_samples 10 \
    --output_folder results/swe-bench-verified_${EXP_NAME}/reproduction_test_samples \
    --output_file reproduction_tests.jsonl \
    --select \
    --dataset=princeton-nlp/SWE-bench_Verified \
    --model=deepseek-r1 \
    --backend=deepseek-sgl

folder=results/swe-bench-verified_${EXP_NAME}/repair_sample_1
for num in {0..9..1}; do
    run_id_prefix=$(basename $folder); 
    python agentless/test/run_reproduction_tests.py --test_jsonl results/swe-bench-verified_${EXP_NAME}/reproduction_test_samples/reproduction_tests.jsonl \
    --predictions_path="${folder}/output_${num}_processed.jsonl" \
    --run_id="${run_id_prefix}_reproduction_${num}" \
    --num_workers 10 \
    --dataset=princeton-nlp/SWE-bench_Verified;
done

python agentless/repair/rerank.py --patch_folder results/swe-bench-verified_${EXP_NAME}/repair_sample_1/ \
    --output_file results/swe-bench-verified_${EXP_NAME}/all_preds.jsonl \
    --num_samples 10 \
    --deduplicate \
    --regression \
    --reproduction

