#!/bin/bash
cd /usr/lib/wsl/lib
rm libcuda.so libcuda.so.1
ln -s libcuda.so.1.1 libcuda.so.1
ln -s libcuda.so.1 libcuda.so
ldconfig
