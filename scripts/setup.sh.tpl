#!/bin/bash
cos_bucket_name="${model_cos_bucket_name}"
inference_dir="${inference_directory}"
region="${region}"
model_dir="$inference_dir/model.local"
huggingface_model="${model_huggingface_name}"
trusted_profile_id="${trusted_profile_id}"
vpc_metadata_api_endpoint="169.254.169.254"

# Wait for network
until ping -c1 clis.cloud.ibm.com >/dev/null 2>&1; do :; done
echo Network found

# Install venv
apt update
NEEDRESTART_MODE=a apt install -y python3-venv

# Install Nvidia drivers if detected (no CUDA)
if [[ $(lspci | grep NVIDIA &>/dev/null; echo $?) -eq 0 ]]; then
    curl -L https://github.com/IBM/nvidia-cuda-driver/releases/latest/download/install.sh | bash -s -- -c n
fi

if [[ -n "$cos_bucket_name" ]]; then
    # Update and install json/xml tools
    NEEDRESTART_MODE=a apt install -y jq xq

    # Get IAM token
    instance_identity_token=$(curl -X PUT "$vpc_metadata_api_endpoint/instance_identity/v1/token?version=2025-01-07" \
        -H "Metadata-Flavor: ibm" \
        -d '{}' \
        | jq -r '(.access_token)')
    iam_token=$(curl -X POST "$vpc_metadata_api_endpoint/instance_identity/v1/iam_token?version=2025-01-07" \
        -H "Authorization: Bearer $instance_identity_token" \
        -d "{ \"trusted_profile\": { \"id\": \"$trusted_profile_id\" } }" \
        | jq -r '(.access_token)')

    # Get bucket contents
    f_result=/tmp/objects.xml
    curl "https://s3.$region.cloud-object-storage.appdomain.cloud/$cos_bucket_name" \
        -H "Authorization: Bearer $iam_token" \
        > $f_result

    # Download model files
    mkdir -p "$model_dir" 2>/dev/null
    while read key; do
        encoded_key=$(jq -Rr '@uri' <<< "$key")
        curl "https://s3.$region.cloud-object-storage.appdomain.cloud/$cos_bucket_name/$encoded_key" \
            -H "Authorization: Bearer $iam_token" \
            > "$model_dir/$key"
    done < <(xq -x //Key "$f_result")
fi

# Setup venv and vllm
mkdir -p "$inference_dir"
cd "$inference_dir" || exit
cp /tmp/inference/* .
python3 -m venv plenv
source plenv/bin/activate
python -m pip install --upgrade pip
pip install --upgrade --force-reinstall vllm

# Run and enable inference server
tee /etc/rc.local <<EOM >/dev/null
#!/bin/bash
$inference_dir/startup.sh
EOM
chmod +x /etc/rc.local
/etc/rc.local

# Cleanup
rm -rf /tmp/inference
rm "$0"
