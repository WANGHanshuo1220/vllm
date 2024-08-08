# This script is run by buildkite to run the benchmarks and upload the results to buildkite

set -ex
set -o pipefail

# cd into parent directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")/.."

(which wget && which curl) || (apt-get update && apt-get install -y wget curl)

# run python-based benchmarks and upload the result to buildkite
# python3 benchmarks/benchmark_latency.py --output-json latency_results.json 2>&1 | tee benchmark_latency.txt
# bench_latency_exit_code=$?

# python3 benchmarks/benchmark_throughput.py --input-len 256 --output-len 256 --output-json throughput_results.json 2>&1 | tee benchmark_throughput.txt
# bench_throughput_exit_code=$?

model="/root/models/facebook/opt-6.7b"
draft="/root/models/facebook/opt-125m"

# run server-based benchmarks and upload the result to buildkite
python3 -m vllm.entrypoints.openai.api_server --model ${model} \
    --speculative-model ${draft} \
    --use-v2-block-manager --num_speculative_tokens 5 &
server_pid=$!

FILE="ShareGPT_V3_unfiltered_cleaned_split.json"
if [ -e "$FILE" ]; then
    echo "$FILE already exist"
else
    echo "$FILE does not exist, downloading it ..."
    wget https://huggingface.co/datasets/anon8231489123/ShareGPT_Vicuna_unfiltered/resolve/main/ShareGPT_V3_unfiltered_cleaned_split.json
    echo "$FILE download done."
fi

# wait for server to start, timeout after 600 seconds
timeout 180 bash -c 'until curl -s localhost:8000/v1/models; do sleep 1; done' || exit 1
python3 benchmarks/benchmark_serving.py \
    --backend vllm \
    --dataset-name sharegpt \
    --dataset-path ./ShareGPT_V3_unfiltered_cleaned_split.json \
    --model ${model} \
    --num-prompts 2 \
    --endpoint /v1/completions \
    --tokenizer ${model} \
    --save-result \
    2>&1 | tee benchmark_serving.txt
bench_serving_exit_code=$?
kill $server_pid

# write the results into a markdown file
echo "### Latency Benchmarks" >> benchmark_results.md
sed -n '1p' benchmark_latency.txt >> benchmark_results.md # first line
echo "" >> benchmark_results.md
sed -n '$p' benchmark_latency.txt >> benchmark_results.md # last line

echo "### Throughput Benchmarks" >> benchmark_results.md
sed -n '1p' benchmark_throughput.txt >> benchmark_results.md # first line
echo "" >> benchmark_results.md
sed -n '$p' benchmark_throughput.txt >> benchmark_results.md # last line

echo "### Serving Benchmarks" >> benchmark_results.md
sed -n '1p' benchmark_serving.txt >> benchmark_results.md # first line
echo "" >> benchmark_results.md
echo '```' >> benchmark_results.md
tail -n 24 benchmark_serving.txt >> benchmark_results.md # last 24 lines
echo '```' >> benchmark_results.md

# if the agent binary is not found, skip uploading the results, exit 0
if [ ! -f /usr/bin/buildkite-agent ]; then
    exit 0
fi

# upload the results to buildkite
buildkite-agent annotate --style "info" --context "benchmark-results" < benchmark_results.md

# exit with the exit code of the benchmarks
if [ $bench_latency_exit_code -ne 0 ]; then
    exit $bench_latency_exit_code
fi

if [ $bench_throughput_exit_code -ne 0 ]; then
    exit $bench_throughput_exit_code
fi

if [ $bench_serving_exit_code -ne 0 ]; then
    exit $bench_serving_exit_code
fi

rm ShareGPT_V3_unfiltered_cleaned_split.json
buildkite-agent artifact upload "*.json"