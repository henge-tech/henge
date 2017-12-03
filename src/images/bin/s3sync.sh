#! /bin/bash

set -ex

aws s3 sync --profile $1 ./images s3://henge/words/
aws s3 sync --profile $1 ./thumbs s3://henge/thumbs/
aws s3 sync --profile $1 ./thumbs-low1 s3://henge/thumbs-low1/
aws s3 sync --profile $1 ./thumbs-low2 s3://henge/thumbs-low2/
aws s3 sync --profile $1 ./thumbs-low3 s3://henge/thumbs-low3/
