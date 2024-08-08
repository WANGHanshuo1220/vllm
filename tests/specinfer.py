from vllm import LLM, SamplingParams
import time
import gc

prompts = [
    "The future of AI is",
    "My name is Peter, and I am",
]
sampling_params = SamplingParams(temperature=0.8, top_p=0.95)

base_model = "/root/models/facebook/opt-6.7b"
draft_model = "/root/models/facebook/opt-125m"

# ===============================================================

# spec_llm = LLM(
#     model=base_model,
#     tensor_parallel_size=4,
#     speculative_model=draft_model,
#     num_speculative_tokens=5,
#     use_v2_block_manager=True,
# )

# spec_t1 = time.time()
# outputs = spec_llm.generate(prompts, sampling_params)
# spec_t2 = time.time()

# for output in outputs:
#     prompt = output.prompt
#     generated_text = output.outputs[0].text
#     print(f"Prompt: {prompt!r}, Generated text: {generated_text!r}")

# print(f"Speculative generation took {spec_t2 - spec_t1} seconds")
# del spec_llm
# gc.collect()

# ===============================================================

base_llm = LLM(
    model=base_model, 
    tensor_parallel_size=1,
    use_v2_block_manager=True,
)

base_t1 = time.time()
outputs = base_llm.generate(prompts, sampling_params)
base_t2 = time.time()
for output in outputs:
    prompt = output.prompt
    generated_text = output.outputs[0].text
    print(f"Prompt: {prompt!r}, Generated text: {generated_text!r}")

print(f"Base generation took {base_t2 - base_t1} seconds")