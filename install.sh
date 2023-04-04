#!/bin/bash
# Safeguard sorta
# TODO:
echo "alpaca_lora_4bit install script"
conda_env=${CONDA_PREFIX##*/}

echo "Conda environment: ${conda_env}"
echo
echo "Press ENTER to continue"
echo "To abort press CTRL+C"
echo "..."
read # Pre-requisites
#conda update -n base -c defaults conda -y
conda create -n "$conda_env" python=3.10
conda activate "$conda_env"
#
conda install pytorch torchvision torchaudio pytorch-cuda=11.7 -c pytorch -c nvidia -y -n "$conda_env"
conda install -c conda-forge cudatoolkit=11.7 -y -n "$conda_env"
conda install -c conda-forge ninja -y -n "$conda_env"
conda install -c conda-forge accelerate -y -n "$conda_env"
conda install -c conda-forge sentencepiece -y -n "$conda_env"
# For oobabooga/text-generation-webui
conda install -c conda-forge gradio -y -n "$conda_env"
conda install markdown -y -n "$conda_env"
# For finetuning
conda install datasets -c conda-forge -y -n "$conda_env"
#conda install triton -c conda-forge -y -n "$conda_env"
pip install --pre -U triton

# Clone alpaca_lora_4bit
git clone https://github.com/johnsmith0031/alpaca_lora_4bit
cd alpaca_lora_4bit
pip install -r requirements.txt 
git clone https://github.com/oobabooga/text-generation-webui.git text-generation-webui-tmp
mv -f text-generation-webui-tmp/{.,}* text-generation-webui/
rmdir text-generation-webui-tmp

# Fix path to autograd_4bit.py for custom_monkey_patch
cd text-generation-webui
ln -s ../autograd_4bit.py ./autograd_4bit.py

echo 'Adding custom_monkey_patch as described here - https://github.com/johnsmith0031/alpaca_lora_4bit#text-generation-webui-monkey-patch'
echo "Backup server.py to server.py.orig"
cp server.py server.py.orig
# Create patch
PATCH_FILE="server_py.patch"
echo "--- server.py.bak       2023-04-01 11:29:25.186487234 +0300" > $PATCH_FILE 
echo "+++ server.py   2023-04-01 11:36:29.506494590 +0300" >> $PATCH_FILE
echo "@@ -1,3 +1,5 @@" >> $PATCH_FILE
echo "+import custom_monkey_patch # apply monkey patch" >> $PATCH_FILE
echo "+import gc" >> $PATCH_FILE
echo " import io" >> $PATCH_FILE
echo "  import json" >> $PATCH_FILE
echo "   import re" >> $PATCH_FILE
patch server.py $PATCH_FILE
echo
echo "You'll have to manually get model and LoRA-module for it"
echo
echo "All done"

