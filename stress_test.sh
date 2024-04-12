#!/bin/bash
sequence_number=$1
url="https://ecojourneys.local.livekit-mmla.org"

# List all paths to the files you want to check
declare -a paths=(
    ""
    "Build/EcoJourneys-WebGL-livekit.0.1.g7d86f92.data"
    "Build/EcoJourneys-WebGL-livekit.0.1.g7d86f92.framework.js"
    "Build/EcoJourneys-WebGL-livekit.0.1.g7d86f92.loader.js"
    "Build/EcoJourneys-WebGL-livekit.0.1.g7d86f92.wasm"
    "index.html"
    "TemplateData/AspectRatio.js"
    "TemplateData/favicon.ico"
    "TemplateData/logo.png"
    "TemplateData/style.css"
    "TemplateData/UnityProgress.js"
)

# Iterate through each file path and perform a curl request
for path in "${paths[@]}"
do
    # Perform the curl operation and capture the output
    output=$(curl -o /dev/null -s -w "%{http_code},%{time_total}," "$url/$path")
    
    # Append date and URL to the output
    echo -e "$sequence_number,$output$(date +%Y-%m-%d-%H:%M:%S),$url/$path"
done
