#!/bin/bash

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="tharundevops.store"
hosted_zone_id="Z0810538STDHNRRVG8YJ"

for instance in $@
do
    echo "Creating instance: $instance"
done