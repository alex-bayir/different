set /p "host=Enter host: "
set /p "user=Enter user: "
set /p "commit=Enter commit id: "
pscp .\vscode*.tar.gz %user%@%host%:/home/%user%
ssh %user%@%host% "rm -rf ~/.vscode-server && mkdir -p ~/.vscode-server/cli/servers/Stable-%commit% && tar -xzf ~/vscode_cli_alpine_x64_cli.tar.gz -C ~/.vscode-server && mv ~/.vscode-server/code ~/.vscode-server/code-%commit% && tar -xzf ~/vscode-server-linux-x64.tar.gz -C ~/.vscode-server/cli/servers/Stable-%commit% && mv ~/.vscode-server/cli/servers/Stable-%commit%/vscode-server-linux-x64 ~/.vscode-server/cli/servers/Stable-%commit%/server && rm ~/vscode*.tar.gz"