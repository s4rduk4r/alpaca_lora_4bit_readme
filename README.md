# alpaca_lora_4bit_readme
[Русская версия](https://github.com/s4rduk4r/alpaca_lora_4bit_readme/blob/main/README-RU.md)

* [Models](https://github.com/s4rduk4r/alpaca_lora_4bit_readme/blob/main/README.md#gptqv2-models)
* [LoRA-modules](https://github.com/s4rduk4r/alpaca_lora_4bit_readme/blob/main/README.md#5-get-lora)

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
### GPTQv2 models:
1. **llama-7b:**
 - https://huggingface.co/Neko-Institute-of-Science/LLaMA-7B-4bit-128g
 - https://huggingface.co/sardukar/llama7b-4bit-v2
2. **llama-13b:**
 - https://huggingface.co/Neko-Institute-of-Science/LLaMA-13B-4bit-128g
 - https://huggingface.co/sardukar/llama13b-4bit-v2
4. **llama-30b:**
 - https://huggingface.co/Neko-Institute-of-Science/LLaMA-30B-4bit-128g
6. **llama-65b:**
 - https://huggingface.co/Neko-Institute-of-Science/LLaMA-65B-4bit-128g

### GPTQv1 models (legacy):
1. **llama-7b** - https://huggingface.co/decapoda-research/llama-7b-hf-int4
2. **llama-13b** - https://huggingface.co/decapoda-research/llama-13b-hf-int4
3. **llama-30b** - https://huggingface.co/decapoda-research/llama-30b-hf-int4
4. **llama-65b** - https://huggingface.co/decapoda-research/llama-65b-hf-int4

```sh
# Navigate to text-generation-webui dir:
cd text-generation-webui
# Download quantized model
python download-model.py --text-only decapoda-research/llama-13b-hf
mv models/llama-13b-hf ../llama-13b-4bit
wget https://huggingface.co/decapoda-research/llama-13b-hf-int4/resolve/main/llama-13b-4bit.pt ../llama-13b-4bit.pt
```

## 5. Get LoRA
Comprehensive list of LoRAs - https://github.com/tloen/alpaca-lora#resources

```sh
# Download LoRA and place it where the custom_monkey patch expects it to be
python download-model.py samwit/alpaca13B-lora
mv loras/alpaca13B-lora ../alpaca13b_lora
```

## 6. Use model for inference
1. [Edit](https://github.com/johnsmith0031/alpaca_lora_4bit#text-generation-webui-monkey-patch) `server.py`. Add at the top of the file this code:
```python
import custom_monkey_patch # apply monkey patch
import gc
```
2. Fix paths to `autograd_4bit` facilities for `custom_monkey_patch`
```sh
ln -s ../autograd_4bit.py ./autograd_4bit.py
ln -s ../matmul_utils_4bit.py matmul_utils_4bit.py
ln -s ../triton_utils.py triton_utils.py
ln -s ../custom_autotune.py custom_autotune.py
```
2. Edit `custom_monkey_patch.py` to be able to load GPTQv2 models

**Important:** 
- groupsize has to be the same as was used during model creation. In the example below it's for size 128. If the model was created without `--groupsize` argument, then value must be `-1`
- LoRA modules produced for GPTQv1 models can produce garbage output

```diff
-    config_path = '../llama-13b-4bit/'
-    model_path = '../llama-13b-4bit.pt'
-    lora_path = '../alpaca13b_lora/'
+    config_path = '/path/to/model/config'
+    model_path = '/path/to/model.safetensors'
+    lora_path = '/path/to/lora'
+
+    autograd_4bit.switch_backend_to('triton')

     print("Loading {} ...".format(model_path))
     t0 = time.time()

-    model, tokenizer = load_llama_model_4bit_low_ram(config_path, model_path, groupsize=-1, is_v1_model=True)
+    model, tokenizer = load_llama_model_4bit_low_ram(config_path, model_path, groupsize=128, is_v1_model=False)
```
3. Start WebUI
```
python server.py
```
