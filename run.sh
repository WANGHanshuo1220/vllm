#!/bin/bash

python3 tests/specinfer.py

# 文件名
filename="/root/vllm/accepted_tokens.txt"

# 初始化累加变量
sum_a=0
sum_b=0

# 逐行读取文件
while IFS=' ' read -r a b; do
    # 累加a和b
    sum_a=$((sum_a + a))
    sum_b=$((sum_b + b))
done < "$filename"

# 计算b/a
if [ "$sum_a" -ne 0 ]; then
    ratio=$(echo "scale=2; $sum_b / $sum_a" | bc)
    echo "Sum of a: $sum_a"
    echo "Sum of b: $sum_b"
    echo "b / a: $ratio"
else
    echo "Sum of a is 0, cannot divide by zero."
fi