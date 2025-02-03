#!/bin/bash

model_or_path="${model_or_path}"

cd "$(dirname "$0")" || exit
source plenv/bin/activate
vllm serve "$model_or_path" --config config.yaml &> /var/log/inference.out &
