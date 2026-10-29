#!/bin/bash

echo "Building..."
g++ -std=c++17 -Wall raw_pointer.cpp -o raw_pointer
g++ -std=c++17 -Wall smart_pointer.cpp -o smart_pointer

echo -e "\n=== Raw Pointer ==="
./raw_pointer

echo -e "\n=== Smart Pointer ==="
./smart_pointer

