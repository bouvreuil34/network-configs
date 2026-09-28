#!/bin/bash
set -e

BASE_URL="https://raw.githubusercontent.com/bouvreuil34/network-configs/main/scripts"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_PATH="$INSTALL_DIR/network-diagnostics-macos.sh"
LAUNCHER="$HOME/Desktop/Проверить интернет.command"

mkdir -p "$INSTALL_DIR"

curl -fsSL "$BASE_URL/network-diagnostics-macos.sh" -o "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

cat > "$LAUNCHER" <<'EOF'
#!/bin/bash
"$HOME/.local/bin/network-diagnostics-macos.sh"
echo
echo "Готово. Файл с результатами уже показан в Finder."
echo "Это окно можно закрыть."
read -n 1 -s -r -p "Нажмите любую клавишу для закрытия..."
EOF

chmod +x "$LAUNCHER"

echo
echo "Готово."
echo "На Рабочем столе появился файл:"
echo "Проверить интернет.command"
echo
echo "Во время сбоя просто дважды нажмите на него."
