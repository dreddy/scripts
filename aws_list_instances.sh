#!/bin/bash


aws ec2 describe-regions --output text |\
cut -f 4 | \
grep us- | \
xargs -I {} aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].[Placement.AvailabilityZone, InstanceId, InstanceType, State.Name, Tags[?Key==`owner`].Value | [0], Tags[?Key==`benchmark`].Value | [0]]' \
    --output text \
    --region {} | \
grep --color 'running\|$'
