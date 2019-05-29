#!/bin/bash
set -eu

for missing_environment_variable in keypair_name security_groups tag_name tag_user tag_project
do
  : ${!missing_environment_variable:?$missing_environment_variable}
done

aminamepattern=dhis2-full/\*

images=$(
    aws ec2 describe-images --owners self --filters "Name=name,Values=$aminamepattern" 'Name=state,Values=available' --output json
)
currentimage=$(
    jq <<<"$images" -S '.Images | sort_by(.CreationDate) | last(.[])'
)
if [ "$currentimage" = null ]
then
  echo >&2 "Error: No AMIs matching name pattern: $aminamepattern"
  exit 1
fi

currentid=$(
    jq <<<"$currentimage" -r '.ImageId'
)
blockdevicemappings=$(
    jq <<<"$currentimage" -c '.BlockDeviceMappings|(.[]|select(.DeviceName=="/dev/sda1")|.Ebs.VolumeSize) |= 16'
)
tags=$(
    jq -n -c \
        --arg Name "$tag_name" \
        --arg User "$tag_user" \
        --arg Project "$tag_project" \
        '[{"Key":"Name","Value":$Name},{"Key":"User","Value":$User},{"Key":"Project","Value":$Project}]'
)
tagspec=$(
    jq -n -c \
        --argjson tags "$tags" \
        '[{"ResourceType":"instance","Tags":$tags},{"ResourceType":"volume","Tags":$tags}]'
)

(
    set -x
    aws ec2 run-instances \
        --image-id "$currentid" \
        --count 1 \
        --instance-type t3.medium \
        --key-name "$keypair_name" \
        --security-groups "$security_groups" \
        --block-device-mappings "$blockdevicemappings" \
        --tag-specifications "$tagspec"
)
