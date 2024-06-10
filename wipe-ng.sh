#!/bin/bash

# Check if user provided a device argument
if [ $# -eq 0 ]; then
  echo "Error: Please specify a device (e.g., /dev/sdX) as an argument."
  lsblk
  exit 1
fi

# Get the device name from the argument
device="$1"

fill_with_one(){
  cat /dev/zero |tr '\0' '\377' | sudo dd of=$device bs=64k status=progress
     pv "$device" | tr --squeeze-repeats "\377" "The Device Wiped Succesfully"
  if [ $? == "The Device Wiped Succesfully" ]; then
    echo "Error: Verification failed during One wipe. Starting Wipe process again."
    fill_with_one
  fi
  echo "one wipe successful."
}

# Function to wipe with zeros and verify
wipe_with_zeros() {
  echo "Wiping $device with zeros..."
  pv < /dev/zero > $device
  if [ $? != "pv: write failed: No space left on device" ]; then
    echo "wipe complete"
  else
    echo "wipe failed"
  fi
  echo "starting verification process"
   pv "$device" | tr --squeeze-repeats "\000" "The Device Wiped Succesfully"
  if [ $? == "The Device Wiped Succesfully" ]; then
    echo "Error: Verification failed during zero wipe. Starting Wipe process again."
    wipe_with_zeros
  fi
  echo "Zero wipe successful."
}

# Wipe with zeros twice
echo "Starting Wiping with Zeros!"
wipe_with_zeros
sleep 5
clear
echo "starting Wiping with one!"
fill_with_one
sleep 5
clear

# Wipe with random data (use shred for secure erase)
echo "Wiping $device with random data"
pv < /dev/urandom > "$device" 
if pv < /dev/urandom > "$device" -ne 0 ; then
  echo "Error: Random data wipe failed."
  exit 1
fi
echo "Random data wipe complete."
sleep 5
clear
echo "Wiping process finished."