# configs

Meus arquivos de configuração (dotfiles), organizados por sistema operacional.

## Estrutura

```
configs/
├── linux/        # Arch Linux
│   ├── hypr/     # configuração do Hyprland
│   └── zshrc     # ~/.zshrc do Linux
└── mac/
    └── zshrc     # ~/.zshrc do macOS
```

## Instalação (Linux / Arch)

Clone o repositório e crie os symlinks:

```bash
git clone https://github.com/RafaelCardoso11/configs ~/configs

ln -sfn ~/configs/linux/hypr  ~/.config/hypr
ln -sf  ~/configs/linux/zshrc ~/.zshrc
```

## Instalação (macOS)

```bash
ln -sf ~/configs/mac/zshrc ~/.zshrc
```
