#! /bin/bash

set -ex

aws s3 sync --profile $1 ./images s3://henge/words/
aws s3 sync --profile $1 ./thumbs s3://henge/thumbs/
