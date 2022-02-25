#! /bin/bash

set -ex

aws s3 sync ./images s3://henge/words/
aws s3 sync ./thumbs s3://henge/thumbs/
aws s3 sync ./thumbs-low1 s3://henge/thumbs-low1/
aws s3 sync ./thumbs-low2 s3://henge/thumbs-low2/
aws s3 sync ./thumbs-low3 s3://henge/thumbs-low3/
aws s3 sync ./circles s3://henge/circles/
