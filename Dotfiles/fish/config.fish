# ~/.config/fish/config.fish

# Desabilitar mensagem de boas-vindas
set -g fish_greeting ""

# Prompt simples
function fish_prompt
    echo -n "> "
end

# Sobrescrever cores para visibilidade em fundo branco
set -g fish_color_normal black
set -g fish_color_command black
set -g fish_color_comment brblack
set -g fish_color_cwd black
set -g fish_color_error brred
set -g fish_color_user black
set -g fish_color_autosuggestion blue
