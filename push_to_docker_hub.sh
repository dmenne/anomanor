#!/bin/bash
TAG=$(awk -v RS='\r\n' '/^Version/ {print $2}' DESCRIPTION)
echo Version from DESCRIPTION: ${TAG}
docker tag anomanor dmenne/anomanor:${TAG}
docker push dmenne/anomanor:${TAG}
