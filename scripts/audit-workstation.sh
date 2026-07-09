apt-mark showmanual > pop-manual-packages.txt

flatpak list --app --columns=application,version,origin > pop-flatpak-apps.txt

code --list-extensions --show-versions > vscode-extensions.txt

pip list --user > pip-user-packages.txt
