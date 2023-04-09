# alpaca_lora_4bit_readme русская версия

[English version](https://github.com/s4rduk4r/alpaca_lora_4bit_readme/blob/main/README.md)

* [Модели](https://github.com/s4rduk4r/alpaca_lora_4bit_readme/blob/main/README-RU.md#gptqv2-%D0%BC%D0%BE%D0%B4%D0%B5%D0%BB%D0%B8) 
* [LoRA-модули](https://github.com/s4rduk4r/alpaca_lora_4bit_readme/blob/main/README-RU.md#5-%D1%81%D0%BA%D0%B0%D1%87%D0%B0%D0%B9%D1%82%D0%B5-lora-%D0%BC%D0%BE%D0%B4%D1%83%D0%BB%D1%8C)

Небольшое руководство к коду https://github.com/johnsmith0031/alpaca_lora_4bit

Создано: 22.03.2023

Содержимое файла может обновляться

Всё было проверено на Windows 10 22H2 в WSL. Для Linux последовательность действий должна быть аналогичной

# Подготовка:
1. Включить WSL 2.0. Подробнее здесь - https://learn.microsoft.com/ru-ru/windows/wsl/install
2. Установить Ubuntu 22.04.2LTS (вероятно подойдёт любой дистрибутив Ubuntu)
3. NVIDIA GPU Drivers + CUDA Toolkit 11.7 + CUDA Toolkit 11.7 WSL Ubuntu
4. Miniconda for Linux - https://docs.conda.io/en/latest/miniconda.html

# NVidia CUDA Toolkit фикс для bitsandbytes
1. Создайте скрипт (или возьмите из [репозитория](https://github.com/s4rduk4r/alpaca_lora_4bit_readme/blob/main/fix_cuda.sh "fix_cuda.sh")) для воссоздания симлинков к CUDA библиотекам - https://forums.developer.nvidia.com/t/wsl2-libcuda-so-and-libcuda-so-1-should-be-symlink/236301
```sh
#!/bin/bash
cd /usr/lib/wsl/lib
rm libcuda.so libcuda.so.1
ln -s libcuda.so.1.1 libcuda.so.1
ln -s libcuda.so.1 libcuda.so
ldconfig
```

2. Сохраните его как fix_cuda.sh в директории $HOME
3. Сделайте файл исполняемым
```sh
chmod u+x $HOME/fix_cuda.sh
```
4. Уберите необходимость использования пароля при выполнении `sudo`

```sh
sudo visudo
```

В редакторе замените строку
```sh
%sudo   ALL=(ALL:ALL) ALL
```
на
```sh
%sudo   ALL=(ALL:ALL) NOPASSWD:ALL
```
Сохраните файл (`Ctrl+O`) и закройте редактор (`Ctrl+X`)

Проверить что всё работает можно выполнив `sudo -ll`. Команда должна отработать без предварительного запроса пароля

5. Автоматизируйте применение фикса при каждом входе
```sh
echo 'sudo $HOME/fix_cuda.sh' >> ~/.bashrc
```
6. После установки CUDA Toolkit for WSL Ubuntu необходимо отредактировать два файла:
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
Активируйте созданное окружение:
```sh
conda activate <YOUR_ENV_NAME_HERE>
```

## 2. Установите библиотеки
```sh
conda install pytorch torchvision torchaudio pytorch-cuda=11.7 -c pytorch -c nvidia
conda install -c conda-forge cudatoolkit=11.7
conda install -c conda-forge ninja
conda install -c conda-forge accelerate
conda install -c conda-forge sentencepiece
# Для oobabooga/text-generation-webui
conda install -c conda-forge gradio
conda install markdown
# Для finetuning
conda install datasets -c conda-forge
```

## 3. Клонируйте репозиторий `alpaca_lora_4bit`
```sh
git clone https://github.com/johnsmith0031/alpaca_lora_4bit
cd alpaca_lora_4bit
pip install -r requirements.txt
git clone https://github.com/oobabooga/text-generation-webui.git text-generation-webui-tmp
mv -f text-generation-webui-tmp/{.,}* text-generation-webui/
rmdir text-generation-webui-tmp
```

## 4. Скачайте модель
### GPTQv2 модели:
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

### GPTQv1 модели (устаревшие):
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

## 5. Скачайте LoRA-модуль
Полный список LoRA-модулей можно найти здесь - https://github.com/tloen/alpaca-lora#resources

```sh
# Download LoRA and place it where the custom_monkey patch expects it to be
python download-model.py samwit/alpaca13B-lora
mv loras/alpaca13B-lora ../alpaca13b_lora
```

## 6. Используйте модель
1. [Отредактируйте](https://github.com/johnsmith0031/alpaca_lora_4bit#text-generation-webui-monkey-patch) `server.py`. В начало файла добвьте код:
```python
import custom_monkey_patch # apply monkey patch
import gc
```
2. Восстановить путь к autograd_4bit.py для custom_monkey_patch
```sh
ln -s ../autograd_4bit.py ./autograd_4bit.py
```
3. Запустить WebUI
```
python server.py
```
