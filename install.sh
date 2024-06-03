#!/bin/bash

# Ensure the script is run with superuser privileges on Unix systems
if [[ "$OSTYPE" != "msys" && "$EUID" -ne 0 ]]; then
  echo "Please run as root"
  exit
fi

# Install Zsh and Oh My Zsh
install_zsh() {
  if ! command -v zsh &> /dev/null; then
    echo "Installing Zsh..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
      brew install zsh
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      if command -v apt-get &> /dev/null; then
        apt-get install -y zsh
      elif command -v yum &> /dev/null; then
        yum install -y zsh
      elif command -v pacman &> /dev/null; then
        pacman -S --noconfirm zsh
      fi
    fi
  else
    echo "Zsh is already installed"
  fi

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "Oh My Zsh is already installed"
  fi

  if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting" ]]; then
    echo "Installing fast-syntax-highlighting plugin..."
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
  else
    echo "fast-syntax-highlighting is already installed"
  fi

  if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/catppuccin" ]]; then
    echo "Installing zsh-fsh theme..."
    git clone https://github.com/catppuccin/zsh-fsh.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/catppuccin
  else
    echo "zsh-fsh theme is already installed"
  fi

  if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab" ]]; then
    echo "Installing fzf-tab plugin..."
    git clone https://github.com/Aloxaf/fzf-tab.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab
  else
    echo "fzf-tab plugin is already installed"
  fi

  echo "Configuring .zshrc..."
  cat <<EOF >> $HOME/.zshrc
# Set the zsh theme
ZSH_THEME="catppuccin"

# Enable plugins
plugins=(git sudo fast-syntax-highlighting fzf-tab)

# Load Oh My Zsh
source \$HOME/.oh-my-zsh/oh-my-zsh.sh

# Configure fzf history search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Use fzf for history search
export FZF_DEFAULT_COMMAND='history -10000'
export FZF_CTRL_R_OPTS='--preview "echo {}"'
EOF
  echo "Completed .zshrc configuration..."
}

install_zsh

# Detect OS
OS=$(uname -s)

install_homebrew() {
  if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Homebrew is already installed"
  fi
}

 install_linuxbrew() {
  if ! command -v brew &> /dev/null; then
    echo "Installing Linuxbrew..."
    sudo -u "$SUDO_USER" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    sudo -u "$SUDO_USER" /bin/bash -c "(echo; echo 'eval \"$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"') >> /home/$SUDO_USER/.bashrc"
    sudo -u "$SUDO_USER" /bin/bash -c "eval \"$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\""
    
    # Add Linuxbrew bin to the PATH
    sudo -u "$SUDO_USER" /bin/bash -c "(echo; echo 'export PATH=\"/home/linuxbrew/.linuxbrew/bin:\$PATH\"') >> /home/$SUDO_USER/.bashrc"
    sudo -u "$SUDO_USER" /bin/bash -c "export PATH=\"/home/linuxbrew/.linuxbrew/bin:\$PATH\""
      
    sudo -u "$SUDO_USER" /bin/bash -c "source /home/$SUDO_USER/.bashrc"
  else
    echo "Linuxbrew is already installed"
  fi
}

install_chocolatey() {
  if [[ "$OSTYPE" == "msys" ]]; then
    if ! command -v choco &> /dev/null; then
      echo "Installing Chocolatey..."
      powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    else
      echo "Chocolatey is already installed"
    fi
  else
    echo "Skipping Chocolatey installation, not supported on this OS"
  fi
}
  
install_common_linux_macos() {
  if [[ "$OS" == "Darwin" ]]; then
    install_homebrew
  elif [[ "$OS" == "Linux" ]]; then
    install_linuxbrew
  fi

  # Update package lists
  if command -v apt-get &> /dev/null; then
    echo "Updating package lists..."
    apt-get update
  fi



# Install languages and tools as the non-root user
  sudo -u "$SUDO_USER" /bin/bash <<EOF
    echo "Sourcing the .bashrc to ensure brew is in the PATH..."
    source /home/$SUDO_USER/.bashrc

    echo "Installing languages..."
    eval "\$($(brew --prefix)/bin/brew shellenv)"
    brew install zig rust go php ocaml python node bun elixir openjdk@11 lua

    echo "Installing C#..."
    brew tap isen-ng/dotnet-sdk-versions
    if [[ "$OSTYPE" == "darwin"* ]]; then
      brew install --cask dotnet-sdk7
      brew install --cask dotnet-sdk8
    else
      brew install dotnet-sdk7
      brew install dotnet-sdk8
    fi

    echo "Installing C++ (GPP)..."
    if command -v apt-get &> /dev/null; then
      sudo apt-get install -y g++
    else
      brew install gcc
    fi

    echo "Installing Helix editor..."
    brew install helix

    echo "Installing LSPs..."
    brew install clangd omnisharp-mono docker vscode-css-languageserver vscode-html-languageserver jdtls typescript-language-server vscode-json-languageserver lua-language-server ocaml-lsp pylsp rust-analyzer taplo yaml-language-server zls

    echo "Installing DAPs..."
    brew install lldb netcoredbg delve

    echo "Installing Tools..."
    brew install docker gitui tldr exa scc fzf hyperfine lazydocker kdash oh-my-zsh
EOF
  echo "Finished Installing Languages and Tools"
}



install_common_windows() {
  if [[ "$OS" == "Windows_NT" ]]; then
    install_chocolatey

    # Update Chocolatey
    echo "Updating Chocolatey..."
    choco upgrade chocolatey -y

    # Install sudo if not installed
    if ! command -v sudo &> /dev/null; then
      echo "Installing sudo..."
      choco install sudo -y
    else
      echo "sudo is already installed"
    fi

    # Install languages
    echo "Installing languages..."
    choco install zig rust go php ocaml python nodejs bun elixir jdk11 lua -y

    # Install C#
    echo "Installing C#..."
    choco install dotnet-sdk --version=7.0 -y
    choco install dotnet-sdk --version=8.0 -y

    # Install C++ (GPP)
    echo "Installing C++ (GPP)..."
    choco install mingw -y

    # Install Editor
    echo "Installing Helix editor..."
    choco install helix-editor -y

    # Install LSPs
    echo "Installing LSPs..."
    choco install clangd omnisharp vscode-css-languageserver-bin docker vscode-html-languageserver-bin jdtls typescript-language-server vscode-json-languageserver-bin lua-language-server ocaml-lsp pylsp rust-analyzer taplo yaml-language-server zls -y

    # Install DAPs
    echo "Installing DAPs..."
    choco install lldb netcoredbg delve -y

    # Install Tools
    echo "Installing Tools..."
    choco install docker gitui tldr exa scc fzf hyperfine lazydocker kdash oh-my-posh -y

    # Install PowerShell modules
    echo "Installing PowerShell modules..."
    powershell -Command "Install-Module -Name 'Catppuccin' -Force"
    powershell -Command "Install-Module -Name 'Terminal-Icons' -Force"
    powershell -Command "Install-Module -Name 'PSReadLine' -Force"
    powershell -Command "Install-Module -Name 'PSFzf' -Force"
    powershell -Command "Install-Module -Name 'oh-my-posh' -Scope CurrentUser -Force"

    # Generate profile.ps1
    echo "Generating profile.ps1..."
    cat << EOF > profile.ps1
Import-Module Catppuccin

\$Flavor = \$Catppuccin['Mocha']

function prompt {
    \$(if (Test-Path variable:/PSDebugContext) { "\$($Flavor.Red.Foreground())[DBG]: " }
      else { '' }) + "\$($Flavor.Teal.Foreground())PS \$($Flavor.Yellow.Foreground())" + \$(Get-Location) +
        "\$($Flavor.Green.Foreground())" + \$(if (\$NestedPromptLevel -ge 1) { '>>' }) + '> ' + \$(\$PSStyle.Reset)
}

\$ENV:FZF_DEFAULT_OPTS = @"
--color=bg+:\$($Flavor.Surface0),bg:\$($Flavor.Base),spinner:\$($Flavor.Rosewater)
--color=hl:\$($Flavor.Red),fg:\$($Flavor.Text),header:\$($Flavor.Red)
--color=info:\$($Flavor.Mauve),pointer:\$($Flavor.Rosewater),marker:\$($Flavor.Rosewater)
--color=fg+:\$($Flavor.Text),prompt:\$($Flavor.Mauve),hl+:\$($Flavor.Red)
--color=border:\$($Flavor.Surface2)
"@

\$Colors = @{
    # Largely based on the Code Editor style guide
    # Emphasis, ListPrediction and ListPredictionSelected are inspired by the Catppuccin fzf theme

    # Powershell colours
    ContinuationPrompt     = \$Flavor.Teal.Foreground()
    Emphasis               = \$Flavor.Red.Foreground()
    Selection              = \$Flavor.Surface0.Background()

    # PSReadLine prediction colours
    InlinePrediction       = \$Flavor.Overlay0.Foreground()
    ListPrediction         = \$Flavor.Mauve.Foreground()
    ListPredictionSelected = \$Flavor.Surface0.Background()

    # Syntax highlighting
    Command                = \$Flavor.Blue.Foreground()
    Comment                = \$Flavor.Overlay0.Foreground()
    Default                = \$Flavor.Text.Foreground()
    Error                  = \$Flavor.Red.Foreground()
    Keyword                = \$Flavor.Mauve.Foreground()
    Member                 = \$Flavor.Rosewater.Foreground()
    Number                 = \$Flavor.Peach.Foreground()
    Operator               = \$Flavor.Sky.Foreground()
    Parameter              = \$Flavor.Pink.Foreground()
    String                 = \$Flavor.Green.Foreground()
    Type                   = \$Flavor.Yellow.Foreground()
    Variable               = \$Flavor.Lavender.Foreground()
}

# Set the colours
Set-PSReadLineOption -Colors \$Colors

\$PSStyle.Formatting.Debug = \$Flavor.Sky.Foreground()
\$PSStyle.Formatting.Error = \$Flavor.Red.Foreground()
\$PSStyle.Formatting.ErrorAccent = \$Flavor.Blue.Foreground()
\$PSStyle.Formatting.FormatAccent = \$Flavor.Teal.Foreground()
\$PSStyle.Formatting.TableHeader = \$Flavor.Rosewater.Foreground()
\$PSStyle.Formatting.Verbose = \$Flavor.Yellow.Foreground()
\$PSStyle.Formatting.Warning = \$Flavor.Peach.Foreground()

oh-my-posh init pwsh --config "https://raw.githubusercontent.com/concelare/dotfiles/main/ohmyposhconfig.omp.json" | Invoke-Expression
Import-Module -Name Terminal-Icons
Import-Module PSReadLine
Enable-PowerType
Import-Module PSFzf
Set-PsFzfOption -PSReadLineChordProvider 'Ctrl+f' -PSReadLineChordReverseHistory 'Ctrl+r'
Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
EOF

    # Set Profile
    echo "Adding profile setting to \$PROFILE..."
    powershell -Command "Add-Content -Path \$PROFILE -Value \"`n. `\"\`$PWD/profile.ps1\`\"\""
  else
    echo "This function is only runnable on Windows."
  fi
}
install_common() {
  if [[ "$OS" == "MSYS_NT"* ]]; then
    install_common_windows
  else
    install_common_linux_macos
  fi

  generate_helix_config
}

generate_helix_config() {
  HELIX_CONFIG_DIR_LINUX="/home/$SUDO_USER/.config/helix"
  HELIX_CONFIG_DIR_WINDOWS="$APPDATA/helix"

  echo "Creating Helix configuration directory..."
  if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
    mkdir -p "$HELIX_CONFIG_DIR_LINUX/themes"

    echo "Downloading theme file..."
    curl -fsSL -o "$HELIX_CONFIG_DIR_LINUX/themes/catppuccin_mocha.toml" https://raw.githubusercontent.com/catppuccin/helix/main/themes/default/catppuccin_mocha.toml

    echo "Generating helix config.toml..."
    cat <<EOF > "$HELIX_CONFIG_DIR_LINUX/config.toml"
theme = "catppuccin_mocha"

[editor]
cursorline = true
color-modes = true
true-color = true
auto-save = true

[editor.cursor-shape]
insert = "bar"
normal = "block"
select = "underline"

[editor.indent-guides]
render = true

[editor.lsp]
display-messages = true
display-inlay-hints = true
EOF
  elif [[ "$OSTYPE" == "msys" ]]; then
    mkdir -p "$HELIX_CONFIG_DIR_WINDOWS/themes"

    echo "Downloading theme file..."
    curl -fsSL -o "$HELIX_CONFIG_DIR_WINDOWS/themes/catppuccin_mocha.toml" https://raw.githubusercontent.com/catppuccin/helix/main/themes/default/catppuccin_mocha.toml

    echo "Generating helix config.toml..."
    cat <<EOF > "$HELIX_CONFIG_DIR_WINDOWS/config.toml"
theme = "catppuccin_mocha"

[editor]
cursorline = true
color-modes = true
true-color = true
auto-save = true

[editor.cursor-shape]
insert = "bar"
normal = "block"
select = "underline"

[editor.indent-guides]
render = true

[editor.lsp]
display-messages = true
display-inlay-hints = true
EOF
  fi
}


install_nerdfont_jetbrains_mono() {
  echo "Downloading Nerd Fonts (JetBrains Mono)..."
  curl -fsSL -o JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/JetBrainsMono.zip

  echo "Installing necessary tools..."
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Install unzip and fontconfig if not installed
    if ! command -v unzip &> /dev/null; then
      echo "Installing unzip..."
      sudo apt-get update && sudo apt-get install -y unzip
    fi
    if ! command -v fc-cache &> /dev/null; then
      echo "Installing fontconfig..."
      sudo apt-get update && sudo apt-get install -y fontconfig
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: install unzip and fontconfig with brew if not installed
    if ! command -v unzip &> /dev/null; then
      echo "Installing unzip..."
      brew install unzip
    fi
    if ! command -v fc-cache &> /dev/null; then
      echo "Installing fontconfig..."
      brew install fontconfig
    fi
  fi

  echo "Extracting Nerd Fonts..."
  if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
    sudo unzip -o JetBrainsMono.zip -d /usr/share/fonts
    sudo fc-cache -f -v
  elif [[ "$OSTYPE" == "mingw"* || "$OSTYPE" == "msys"* ]]; then
    mkdir -p "C:\\Windows\\Fonts\\JetBrainsMono"
    tar -xzf JetBrainsMono.zip -C "C:\\Windows\\Fonts\\JetBrainsMono"
  fi

  echo "Nerd Fonts (JetBrains Mono) installation completed!"
}

# Main installation
case "$OS" in
  "Darwin"|"Linux")
    echo "Detected $OS. Starting installation for Linux/macOS..."
    install_common
    ;;
  "MINGW32_NT"|"MINGW64_NT"|"MSYS_NT"|"CYGWIN_NT")
    echo "Detected Windows. Starting installation for Windows..."
    install_common
    ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

# Install Jetbrains mono font
install_nerdfont_jetbrains_mono

echo "Installation completed!"
