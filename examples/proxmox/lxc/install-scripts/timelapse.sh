#!/bin/bash

# Variables
base_directory="/data"
frame_rate=30
current_date=$(date +"%Y%m%d")
remote_user="ftpuser"
remote_host="192.168.100.9"
remote_path="/srv/dev-disk-by-uuid-b6592a75-a8da-45d2-ab26-590455950303/hausbau/videos"
mode="${1:-day}" # Default to 'day', use 'all' to process all images
test="${2:-full}" # Add a test mode flag. Use "./script_name.sh true" to enable test mode.

# Function to check if ffmpeg is installed
check_ffmpeg_installed() {
    if ! command -v ffmpeg &> /dev/null
    then
        echo "ffmpeg could not be found, please install it."
        exit 1
    fi
}

# Check if ffmpeg is installed
check_ffmpeg_installed

# Create videos directory if it does not exist
videos_directory="${base_directory}/videos"
mkdir -p "$videos_directory"

# Iterate over each subfolder
for subfolder in "$base_directory"/*/; do
    # Skip if not a directory
    [ -d "$subfolder" ] || continue

    # Subfolder name
    subfolder_name=$(basename "$subfolder")

    # Temporary file for storing image file list
    temp_file_list=$(mktemp /tmp/ffmpeg-images.XXXXXX.txt)

    # Conditionally find images based on the chosen mode
    if [ "$mode" = "all" ]; then
    find "$subfolder" -maxdepth 1 -name "*.JPG" -type f -print0 | sort -z |
    while IFS= read -r -d '' image_file; do
        echo "file '$image_file'" >> "$temp_file_list"
    done
else
        find "$subfolder" -maxdepth 1 -name "${current_date}*.JPG" -type f -print0 | sort -z |
        while IFS= read -r -d '' image_file; do
            echo "file '$image_file'" >> "$temp_file_list"
        done
    fi

    # Proceed with video creation if images are found
    if [ -s "$temp_file_list" ]; then
        # Output video file name, include "test" in the name if in test mode
        if [ "$test" = "test" ]; then
            output_video="${videos_directory}/${subfolder_name}_test_${current_date}.mp4"
        else
            output_video="${videos_directory}/${subfolder_name}_${current_date}.mp4"
        fi

        # Choose encoding settings based on test mode
        if [ "$test" = "test" ]; then
            # Test mode: Create a smaller, lower-resolution video (e.g., 1080p)
            ffmpeg -y -f concat -safe 0 -i "$temp_file_list" -framerate $frame_rate -vf "scale=1920:-2" -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p "$output_video"
        else
            # Normal mode: Create a full-resolution video
            ffmpeg -y -f concat -safe 0 -i "$temp_file_list" -framerate $frame_rate -vf "scale=3840:-1" -c:v libx264 -preset veryslow -crf 18 -pix_fmt yuv420p "$output_video"
        fi

        echo "Video created: $output_video"

        # Optionally, copy and remove the video file
        # scp "$output_video" $remote_user@$remote_host:$remote_path
        # rm "$output_video"
    else
        echo "No images found for the selected mode in $subfolder_name"
    fi

    # Cleanup
    rm "$temp_file_list"
done
