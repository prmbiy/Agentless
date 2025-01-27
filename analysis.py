# from dev.util.cost import cost
# import os

# path = 'results/swe-bench-verified-1'
# tokens = []
# for i in os.listdir(path):
#     if not os.path.isfile(os.path.join(path, i)):
#         for j in os.listdir(f'{path}/{i}'):
#             if j.endswith('outputs.jsonl'):
#                 # print(f'{path}/{i}/{j}')
#                 tokens.append(cost(f'{path}/{i}/{j}'))

# sum_prompt = sum_completion = 0
# for (i, j) in tokens:
#     sum_prompt += i
#     sum_completion += j

# print(sum_prompt, sum_completion)


# from datasets import load_dataset
# swe_bench_data = load_dataset('princeton-nlp/SWE-bench_Verified', split="test")
# # swe_bench_data = [x for x in swe_bench_data if x["instance_id"]]
# def filter_swebench(swe_bench_data):
#     with open('instance_ids.txt') as f:
#         instance_ids = f.read()
#     instance_ids = instance_ids.splitlines()
#     return swe_bench_data.filter(lambda x: x.get("instance_id") in instance_ids)
# swe_bench_data = filter_swebench(swe_bench_data)
# print(swe_bench_data)

# import docker

# SWE_INSTANCE_IMAGE_PREFIX = "sweb.eval.x86_64."
# ACR_LOGIN_SERVER = "codeexecservice.azurecr.io"
# def prepare_image(client, instance_id):
#     full_image_name = f"{SWE_INSTANCE_IMAGE_PREFIX}{instance_id}:latest"
#     try:
#         client.images.get(full_image_name)
#         print(f"Instance image {instance_id} already exists locally, skipping...")
#     except docker.errors.ImageNotFound:
#         print(f"Pulling instance image {instance_id} from ACR...")
#         image = client.images.pull(f"{ACR_LOGIN_SERVER}/{full_image_name}")
#         image.tag(f"{SWE_INSTANCE_IMAGE_PREFIX}{instance_id}", tag="latest")
#         client.images.remove(f"{ACR_LOGIN_SERVER}/{full_image_name}", force=True)

# with open('instance_ids.txt') as f:
#     instance_ids = f.read().splitlines()

# for i in instance_ids:
#     prepare_image(docker.from_env(), i)

# curl  http://4.206.8.65:30000/v1/chat/completions \
# -H "Content-Type: application/json" \
# -H "Authorization: Bearer  " \
# -d '{
# "model": "deepseek-reasoner",
# "messages": [
# {"role": "system", "content": "You are a helpful assistant."},
# {"role": "user", "content": "Hello!"}
# ],
# "stream": false
# }'

from openai import OpenAI

api_key = "test" # place random string

client = OpenAI(api_key=api_key, base_url="http://4.206.8.65:30000/v1")

response = client.chat.completions.create(
    model="deepseek-reasoner",
    messages=[
        {"role": "system", "content": "You are a helpful assistant"},
        {"role": "user", "content": "9.11 vs 9.8, which one is bigger"},
    ],
    stream=False,
    max_tokens=500,
)

print(response.choices[0].message.content)
