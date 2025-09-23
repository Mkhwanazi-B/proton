#!/bin/bash
cd terraform-vprofile
terraform validate
if [ $? -eq 0 ]; then
  echo "Validation passed"
else
  echo "Validation failed"
  exit 1
fi