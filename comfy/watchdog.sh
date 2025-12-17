#!/usr/bin/env bash

# Universal Watchdog (R2 / AWS / Wasabi / DigitalOcean)
OUTPUT_DIR="/comfyui/output"
INTERVAL=30

echo "🛡️ Watchdog: Service started (Secure Mode)..."

while true; do
  sleep $INTERVAL

  # 1. Security Check: Do we have keys?
  if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    continue
  fi

  # 2. Activity Check: Is there anything to upload?
  if [ -z "$(ls -A $OUTPUT_DIR)" ]; then
    continue
  fi

  # 3. DETERMINE ENDPOINT MODE
  # PRIORITY 1: Custom Endpoint (Wasabi, DigitalOcean, MinIO)
  if [ -n "$S3_ENDPOINT_URL" ]; then
    ENDPOINT_FLAG="--endpoint-url $S3_ENDPOINT_URL"
    TARGET_NAME="Custom S3 (Endpoint hidden)"
  
  # PRIORITY 2: Cloudflare R2 (Auto-built from Account ID)
  elif [ -n "$R2_ACCOUNT_ID" ]; then
    ENDPOINT_FLAG="--endpoint-url https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
    TARGET_NAME="Cloudflare R2"

  # PRIORITY 3: Standard AWS S3 (Default)
  else
    ENDPOINT_FLAG=""
    TARGET_NAME="Standard AWS S3"
  fi

  echo "Watchdog: Syncing files to $TARGET_NAME..."

  # 4. Sync Command
  # We suppress stdout to prevent file names from leaking in logs, but keep stderr for errors
  aws s3 sync "$OUTPUT_DIR" "s3://${R2_BUCKET}/output" \
    $ENDPOINT_FLAG \
    --no-progress > /dev/null

  # 5. Cleanup (Only if sync was successful)
  if [ $? -eq 0 ]; then
    rm -rf "$OUTPUT_DIR"/*
    echo "Watchdog: Upload complete. Local cache cleared."
  else
    echo "Watchdog: Upload failed. Retrying next cycle."
  fi
done
