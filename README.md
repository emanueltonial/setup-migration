# setup-migration

Automação em Ansible pra migrar minha workstation do **Pop!_OS** pro **Fedora**. Formatou a máquina, rodou um comando, voltou tudo: repositórios, pacotes, Flatpaks e extensões do VS Code.

> [!NOTE]
> Projeto pessoal, nascido de um problema real: reinstalar o sistema e perder horas lembrando o que eu tinha instalado e configurado. Agora o ambiente é código, versionado e reproduzível.

## O problema

Trocar de distro na mão significa:

- lembrar de dezenas de pacotes, apps e extensões que foram se acumulando com o tempo
- reinstalar tudo clicando e digitando comando por comando
- nunca ter certeza de que o ambiente novo é igual ao antigo

A ideia aqui foi **exportar o estado do sistema antigo** (as listas `pop-*.txt` e `vscode-extensions.txt`), transformar isso em variáveis e deixar o Ansible reconstruir o ambiente no Fedora de forma declarativa.

## O que ele provisiona

| Role | O que faz | Precisa de root |
|---|---|---|
| `repos` | Configura os repositórios de terceiros no Fedora | sim |
| `dnf_packages` | Instala os pacotes via DNF | sim |
| `vscode_extensions` | Instala as extensões do VS Code | não |
| `flatpak_apps` | Instala os apps via Flatpak | não |

A ordem importa: os repositórios entram **antes** dos pacotes, porque parte dos pacotes só existe em repo de terceiros.

## Estrutura

```
setup-migration/
├── workstation.yaml        # playbook principal
├── ansible.cfg             # inventário padrão, roles_path, interpretador
├── requirements.yaml       # collections necessárias (community.general)
├── inventory/
│   └── hosts.yaml          # hosts alvo
├── roles/                  # repos, dnf_packages, vscode_extensions, flatpak_apps
├── vars/                   # listas declarativas do que instalar
│   ├── repos.yaml
│   ├── dnf_packages.yaml
│   ├── flatpak_apps.yaml
│   └── vscode_extensions.yaml
├── scripts/                # scripts auxiliares
├── pop-flatpak-apps.txt    # export do Pop!_OS (referência da migração)
├── pop-manual-packages.txt # export do Pop!_OS (referência da migração)
└── vscode-extensions.txt   # export das extensões do VS Code
```

> [!TIP]
> O que instalar fica em `vars/`, separado da lógica em `roles/`. Pra adicionar um app novo você só edita uma lista, sem mexer em task nenhuma.

## Requisitos

- Fedora (alvo do playbook)
- Ansible instalado na máquina que vai rodar
- Collection `community.general` `>= 8.0.0`
- Acesso `sudo` (as roles de repos e DNF usam `become`)

## Como usar

**1. Instale o Ansible e clone o repo**

```bash
sudo dnf install -y ansible git
git clone https://github.com/emanueltonial/setup-migration.git
cd setup-migration
```

**2. Instale as collections**

```bash
ansible-galaxy collection install -r requirements.yaml
```

**3. Veja o que vai mudar antes de aplicar**

```bash
ansible-playbook workstation.yaml --check --diff --ask-become-pass
```

**4. Aplique**

```bash
ansible-playbook workstation.yaml --ask-become-pass
```

> [!NOTE]
> O inventário padrão fica em `inventory/hosts.yaml` (definido no `ansible.cfg`). Pra provisionar a própria máquina, o host precisa ser `localhost` com `ansible_connection: local`.

### Rodando só uma parte

Cada role tem uma tag, então dá pra reaplicar só o que interessa:

```bash
ansible-playbook workstation.yaml --tags dnf_packages --ask-become-pass
ansible-playbook workstation.yaml --tags flatpak_apps,vscode_extensions
```

| Tag | Role |
|---|---|
| `repos` | repositórios |
| `dnf_packages` | pacotes DNF |
| `vscode_extensions` | extensões do VS Code |
| `flatpak_apps` | apps Flatpak |

## Decisões de projeto

- **Dados separados da lógica.** As listas ficam em `vars/`, as tasks em `roles/`. Mudar o que instalar não exige mexer no código.
- **Uma role por responsabilidade.** Repos, DNF, Flatpak e VS Code são independentes e rodam isoladas por tag.
- **Privilégio mínimo.** Só `repos` e `dnf_packages` rodam com `become`. Flatpak e extensões do VS Code rodam como usuário normal.
- **Dry-run antes de aplicar.** `--check --diff` mostra o que vai mudar sem tocar na máquina.
- **Dependências declaradas.** As collections ficam em `requirements.yaml`, então o setup é reproduzível em outra máquina.

## Lint

Uso [uv](https://docs.astral.sh/uv/) pra gerenciar as ferramentas Python, então o lint roda sem instalar nada no sistema:

```bash
uvx ansible-lint workstation.yaml
```

Ou, se preferir deixar instalado como ferramenta global:

```bash
uv tool install ansible-lint
ansible-lint workstation.yaml
```

## Próximos passos

- [ ] Workflow de `ansible-lint` no GitHub Actions
- [ ] Testes das roles com Molecule
- [ ] Role de dotfiles (shell, git, configs do editor)

## Autor

**Emanuel Tonial**, [@emanueltonial](https://github.com/emanueltonial)
