#!/bin/bash

set -e

chart="$1"
if [[ $1 == sources/* ]]; then 
	chart=$(echo $1 | awk -F'/' '{print $2}')
fi

if [ -z "$chart" ] || [ ! -d sources/$chart ]; then
    echo "Please give the parameter the directory from sources"
    echo "Usage: $0 <chart-name>"
    exit 1
fi

echo "Starting release on $chart"
cd sources/$chart

# Get version
version=$(grep "^version:" Chart.yaml | head -n 1 | awk -F":" '{print $2}' | tr -d ' ')
echo "Version is $version"

# Lint chart
echo "Linting chart..."
helm lint .

# Update dependencies if they exist
if grep -q "dependencies:" Chart.yaml; then
   echo "Updating dependencies"
   helm dependencies update 
fi

cd ../../docs

# Create temp directory
mkdir -p temp
cd temp

# Package chart
echo "Packaging chart..."
helm package ../../sources/$chart

# Update index
echo "Updating repository index..."
helm repo index --merge ../index.yaml .

# Move files
mv * ../
cd ..
rm -rf temp

echo "Successfully updated $chart version $version"
echo "Files updated:"
ls -la *.tgz | grep $chart || echo "No tgz files found"