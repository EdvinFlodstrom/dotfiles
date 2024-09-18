#!/bin/bash

# This script launches NoiseTorch in headless mode and sets its virtual mic as the default.

echo "Starting NoiseTorch for the default microphone..."
noisetorch -i "$(pactl get-default-source)" --headless

echo "Noise suppression has been enabled."
