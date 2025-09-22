#!/bin/bash

date '+%Y-%m-%d %H:%M:%S %z' >> "$LOG_FILE"

sleep $((RANDOM % 4 + 1))
