# alpaca_lora_4bit_readme русская версия
Небольшое руководство к коду https://github.com/johnsmith0031/alpaca_lora_4bit

Создано: 22.03.2023

Содержимое файла может обновляться

Всё было проверено на Windows 10 22H2 в WSL. Для Linux последовательность действий должна быть аналогичной

# Подготовка:
1. Включить WSL 2.0. Подробнее здесь - https://learn.microsoft.com/ru-ru/windows/wsl/install
2. Установить Ubuntu 22.04.2LTS (вероятно подойдёт любой дистрибутив Ubuntu)
3. NVIDIA GPU Drivers + CUDA Toolkit 11.7 + CUDA Toolkit 11.7 WSL Ubuntu
4. Miniconda for Linux - https://docs.conda.io/en/latest/miniconda.html

# NVidia CUDA Toolkit временный фикс для bitsandbytes
1. Создайте скрипт (или возьмите из [репозитория](https://github.com/s4rduk4r/alpaca_lora_4bit_readme/blob/main/fix_cuda.sh "fix_cuda.sh")) для воссоздания симлинков к CUDA библиотекам - https://forums.developer.nvidia.com/t/wsl2-libcuda-so-and-libcuda-so-1-should-be-symlink/236301
```sh
#!/bin/bash
cd /usr/lib/wsl/lib
rm libcuda.so libcuda.so.1
ln -s libcuda.so.1.1 libcuda.so.1
ln -s libcuda.so.1 libcuda.so
ldconfig
```
Сохраните его как fix_cuda.sh в директории $HOME

**Внимание:** скрипт придётся запускать под root при каждом запуске WSL Ubuntu. Например, `sudo $HOME/fix_cuda.sh`

2. После установки CUDA Toolkit for WSL Ubuntu необходимо отредактировать два файла:
  * `/etc/environment` чтобы продолжить текст переменной `PATH=` строкой `:/usr/local/cuda-11.7/bin`
  * `/etc/ld.so.conf.d/cuda-11-7.conf` для добавления в конец файла новой строки `/usr/local/cuda-11.7/lib64`
К счастью, эти изменения постоянные

# Установка:
## 1. Создайте новое окружение conda
```sh
conda update -n base conda
conda create -n <YOUR_ENV_NAME_HERE> python=3.10
# Последние две строки необязательные и нужны для ускорения процесса установки библиотек
# Подробнее - https://www.anaconda.com/blog/a-faster-conda-for-a-growing-community
conda install -n base conda-libmamba-solver
conda config --set solver libmamba
```

## 2. Установите библиотеки
```sh
conda install pytorch torchvision torchaudio pytorch-cuda=11.7 -c pytorch -c nvidia
conda install -c conda-forge cudatoolkit=11.7
conda install -c conda-forge ninja
conda install -c conda-forge accelerate
conda install -c conda-forge sentencepiece
pip install git+https://github.com/huggingface/transformers.git
pip install git+https://github.com/huggingface/peft.git
pip install bitsandbytes
# For oobabooga/text-generation-webui
conda install -c conda-forge gradio
conda install markdown
```

## 3. Клонируйте репозиторий `alpaca_lora_4bit`
```sh
git clone https://github.com/johnsmith0031/alpaca_lora_4bit
cd alpaca_lora_4bit
chmod u+x install.sh
./install.sh
git clone https://github.com/oobabooga/text-generation-webui.git text-generation-webui-tmp
mv -f text-generation-webui-tmp/{.,}* text-generation-webui/
rmdir text-generation-webui-tmp
```

## 4. Скачайте модель
```sh
# Navigate to text-generation-webui dir:
cd text-generation-webui
# Download quantized model
python download-model.py --text-only decapoda-research/llama-13b-hf
mv models/llama-13b-hf ../llama-13b-4bit
wget https://huggingface.co/decapoda-research/llama-13b-hf-int4/resolve/main/llama-13b-4bit.pt ../llama-13b-4bit.pt
```

## 5. Скачайте LoRA-модуль
```sh
# Download LoRA and place it where the custom_monkey patch expects it to be
python download-model.py samwit/alpaca13B-lora
mv loras/alpaca13B-lora ../alpaca13b_lora
```

## 6. Используйте модель
```
python server.py
```
