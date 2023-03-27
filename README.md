# alpaca_lora_4bit_readme
Just a simple HowTo for https://github.com/johnsmith0031/alpaca_lora_4bit

Created on 22.03.2023

This HowTo file can be updated in the future

Everything was tested on Windows 10 22H2 in WSL. For Linux it all should be similar

# Pre-requisites:
1. Activate WSL 2.0. Consult here - https://learn.microsoft.com/en-US/windows/wsl/install
2. Install Ubuntu 22.04.2LTS (probably any Ubuntu will do)
3. NVIDIA GPU Drivers + CUDA Toolkit 11.7 + CUDA Toolkit 11.7 WSL Ubuntu
4. Miniconda for Linux - https://docs.conda.io/en/latest/miniconda.html

# NVidia CUDA Toolkit fix for bitsandbytes
1. Make a script (or take it from [here](https://github.com/s4rduk4r/alpaca_lora_4bit_readme/blob/main/fix_cuda.sh "fix_cuda.sh")) to recreate symlinks for the CUDA libraries - https://forums.developer.nvidia.com/t/wsl2-libcuda-so-and-libcuda-so-1-should-be-symlink/236301
```sh
#!/bin/bash
cd /usr/lib/wsl/lib
rm libcuda.so libcuda.so.1
ln -s libcuda.so.1.1 libcuda.so.1
ln -s libcuda.so.1 libcuda.so
ldconfig
```
2. Save it as fix_cuda.sh in $HOME directory
3. Change permission to executable
```sh
chmod u+x $HOME/fix_cuda.sh
```
4. Make `sudo` command execution passwordless

```sh
sudo visudo
```

In editor change line
```sh
%sudo   ALL=(ALL:ALL) ALL
```
to
```sh
%sudo   ALL=(ALL:ALL) NOPASSWD:ALL
```
Save file (`Ctrl+O`) and exit (`Ctrl+X`)

To check if everything works as intended run `sudo -ll`. Command has to execute without prompting for password

5. Automate fix for each login
```sh
echo 'sudo $HOME/fix_cuda.sh' >> ~/.bashrc
```

6. After installation of CUDA Toolkit for WSL Ubuntu one has to edit two files:
  * `/etc/environment` to add at the end of the `PATH=` string `:/usr/local/cuda-11.7/bin`
  * `/etc/ld.so.conf.d/cuda-11-7.conf` to add at the end of the file additional line `/usr/local/cuda-11.7/lib64`
Thankfully these changes seems to be permanent

# Installation:
## 1. Create new conda environment
```sh
conda update -n base conda
conda create -n <YOUR_ENV_NAME_HERE> python=3.10
# The following two lines are optional to speed up installation process of prerequisites
# More here - https://www.anaconda.com/blog/a-faster-conda-for-a-growing-community
conda install -n base conda-libmamba-solver
conda config --set solver libmamba
```
Activate newly created environment:
```sh
conda activate <YOUR_ENV_NAME_HERE>
```

## 2. Install prerequisites
```sh
conda install pytorch torchvision torchaudio pytorch-cuda=11.7 -c pytorch -c nvidia
conda install -c conda-forge cudatoolkit=11.7
conda install -c conda-forge ninja
conda install -c conda-forge accelerate
conda install -c conda-forge sentencepiece
# For oobabooga/text-generation-webui
conda install -c conda-forge gradio
conda install markdown
# For finetuning
conda install datasets -c conda-forge
```

## 3. Clone `alpaca_lora_4bit`
```sh
git clone https://github.com/johnsmith0031/alpaca_lora_4bit
cd alpaca_lora_4bit
pip install -r requirements.txt
git clone https://github.com/oobabooga/text-generation-webui.git text-generation-webui-tmp
mv -f text-generation-webui-tmp/{.,}* text-generation-webui/
rmdir text-generation-webui-tmp
```

## 4. Get model
```sh
# Navigate to text-generation-webui dir:
cd text-generation-webui
# Download quantized model
python download-model.py --text-only decapoda-research/llama-13b-hf
mv models/llama-13b-hf ../llama-13b-4bit
wget https://huggingface.co/decapoda-research/llama-13b-hf-int4/resolve/main/llama-13b-4bit.pt ../llama-13b-4bit.pt
```

## 5. Get LoRA
```sh
# Download LoRA and place it where the custom_monkey patch expects it to be
python download-model.py samwit/alpaca13B-lora
mv loras/alpaca13B-lora ../alpaca13b_lora
```

## 6. Use model
1. [Edit](https://github.com/johnsmith0031/alpaca_lora_4bit#text-generation-webui-monkey-patch) `server.py`. Add at the top of the file this code:
```python
import custom_monkey_patch # apply monkey patch
import gc
```
3. Fix path to autograd_4bit.py for custom_monkey_patch
```sh
ln -s ../autograd_4bit.py ./autograd_4bit.py
```
3. Start WebUI
```
python server.py
```
