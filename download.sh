#!/bin/bash

# Function to download a file with error checking
download() {
    local url="$1"
    local output="$2"
    echo "Downloading $output from $url..."
    curl -L -o "$output" "$url"
    if [ $? -eq 0 ]; then
        echo "Downloaded $output successfully."
    else
        echo "Failed to download $output."
    fi
}

# Function to process compressed files: decompress and recompress to .tar.xz
process_compressed() {
    local file="$1"
    local ext="${file##*.}"
    local base="${file%.*}"
    local temp_dir="./tmp"
    mkdir -p $temp_dir

    case "$ext" in
        zip)
            unzip "$file" -d "$temp_dir"
            ;;
        gz)
            if [[ "$file" == *.tar.gz ]]; then
                tar -xzf "$file" -C "$temp_dir"
                base="${file%.*.*}"  # Remove .tar.gz
            else
                gunzip -c "$file" > "$temp_dir/$base"
            fi
            ;;
        tgz)
            tar -xzf "$file" -C "$temp_dir"
            base="${file%.*}"  # Remove .tgz
            ;;
        *)
            rm -rf "$temp_dir"
            return
            ;;
    esac

    # Recompress to .tar.xz
    (cd "$temp_dir" && tar -czf "../${base}.tar.gz" .)
    rm -rf "$temp_dir" "$file"
}

# Function to compress single files to .tar.xz
compress_single() {
    local file="$1"
    tar -czf "${file}.tar.gz" "$file"
    rm "$file"
}


# Post-process compressed files
for file in *.zip *.gz; do
    [ -e "$file" ] || continue
    process_compressed "$file"
done

# Compress single files
for file in *.dat *.metadb *.mmdb; do
    [ -e "$file" ] || continue
    compress_single "$file"
done

echo "All downloads and processing completed."

ls -lh
