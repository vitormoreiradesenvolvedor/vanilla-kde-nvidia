# Vanilla OS 3 · KDE Plasma · NVIDIA (notebooks híbridos)

Imagem customizada do [Vanilla OS 3 "Orchid"](https://github.com/Vanilla-OS) com **KDE Plasma**,
**driver NVIDIA proprietário configurado para notebooks híbridos** (iGPU Intel/AMD + dGPU NVIDIA)
e um ambiente de desenvolvimento pronto.

Construída com [Vib](https://github.com/Vanilla-OS/vib) sobre a imagem oficial
`ghcr.io/vanilla-os/core:latest`. Atualizações atômicas via ABRoot, como no Vanilla OS oficial.

## O que vem instalado

| Área | Conteúdo |
|---|---|
| Desktop | KDE Plasma 6, Plasma Login Manager, plasma-setup (criação de usuário no 1º boot), Dolphin, Konsole, KDE Connect, Discover (backends VSO, Flatpak e Snap) |
| NVIDIA híbrido | `nvidia-driver` (550, mesmo patch DKMS do `Vanilla-OS/nvidia-image`), PRIME render offload (`prime-run`, `nrun`), `switcheroo-control`, RTD3 (dGPU desliga ociosa), `nvidia-powerd` (Dynamic Boost), suspend/hibernate/resume da NVIDIA, `nvidia-settings`, `nvtop` |
| Ventoinhas | **NBFC-Linux 0.3.19** (mesma versão da máquina de origem), serviço habilitado, perfil escolhido automaticamente no 1º boot (`nbfc config --set auto`, com fallback pelo modelo DMI) |
| Pacotes | Flatpak (Flathub já configurado), Snap, **Homebrew**, **Nix** (multiusuário, flakes ativos), apx/VSO do Vanilla |
| Containers | Docker (`docker.io`, compose, buildx), Podman/Distrobox (do Vanilla) |
| Linguagens | Python 3 (pip, venv, pipx), Node.js (node, npm, **npx**), **SDKMAN + Java mais recente**, **Rust** (rustup, stable), C/C++ (**gcc, g++, gdb**, gdc, clang, cmake, ninja, valgrind), Git + Git LFS |
| Apps nativos | **Google Chrome**, **DBeaver CE** com **TLS 1.0/1.1 liberado** |
| VPN | WireGuard (+ GUI **wireguird**), OpenVPN, OpenConnect (AnyConnect/GlobalProtect), L2TP/IPsec (strongSwan), PPTP, SSTP, VPNC, **Mullvad VPN** |
| Windows | **Wine** com suporte a programas 32 bits (WoW64), winetricks |
| AppImage | `fuse3`, `libfuse3-4` e `libfuse2t64` (AppImages antigas e novas) + **Gear Lever** |
| Navegador padrão | **Junction**: todo link abre o seletor, que encaminha para o navegador certo seja ele nativo (Chrome), Flatpak (sistema ou usuário), Snap ou AppImage integrada pelo Gear Lever |

## Instalação

1. Baixe a ISO da [última release](../../releases/latest).
   Se a ISO passar de 2 GiB ela vem em partes (`.part00`, `.part01`…): junte com
   `cat Vanilla-OS-KDE-NVIDIA-*.iso.part* > vanilla.iso`.
2. Grave num pendrive (Ventoy, `dd`, Fedora Media Writer…) e dê boot.
3. O instalador baixa a imagem OCI desta release do GHCR, então **precisa de internet**.
4. No 1º boot o plasma-setup cria o usuário. Depois do 1º login:
   - SDKMAN + Java e Rust stable são instalados em segundo plano (alguns minutos);
   - Gear Lever e Junction são instalados do Flathub (precisa de rede; tenta de novo até conseguir);
   - o Homebrew é extraído em `/home/linuxbrew` e seu usuário entra nos grupos `docker`, `nix-users` e `dialout`.
   Faça logout/login uma vez para os grupos valerem.

### Migrar um Vanilla OS 3 já instalado

```sh
abroot rebase ghcr.io/vitormoreiradesenvolvedor/vanilla-kde-nvidia:latest
```

### Atualizar

```sh
abroot upgrade
```

## Uso rápido

```sh
prime-run glxinfo | grep "OpenGL renderer"   # roda na NVIDIA
nbfc status                                   # ventoinhas
nbfc config -r                                # perfis recomendados p/ seu modelo
brew install gh
nix profile install nixpkgs#hello
sdk list java
docker run --rm hello-world
wine programa32.exe
```

### DBeaver e TLS 1.0

O `dbeaver.ini` recebe `-Djava.security.properties=/etc/dbeaver/dbeaver-legacy-tls.security`
(remove TLSv1/TLSv1.1/3DES de `jdk.tls.disabledAlgorithms`) e `-Djdk.tls.client.protocols=TLSv1,…`.
O script `/usr/libexec/dbeaver-enable-legacy-tls` roda no build da imagem e num hook do dpkg
(`/etc/apt/apt.conf.d/99dbeaver-legacy-tls`), então a liberação sobrevive a qualquer atualização.
Para editar a política sem rebuild, mexa em `/etc/dbeaver/dbeaver-legacy-tls.security`.

## Observações

- **Junction**: definido como navegador padrão em `/etc/xdg/mimeapps.list`, no `mimeapps.list` do
  `/etc/skel` e no `kdeglobals` (`BrowserApplication`). Um override de Flatpak expõe ao Junction
  `/usr/share/applications` do host, `/var/lib/flatpak/exports`, `/var/lib/snapd/desktop` e, por
  usuário, `~/.local/share/applications` e `~/.local/share/flatpak/exports`. Ele abre o app
  escolhido no host via `flatpak-spawn --host`.

- **Secure Boot**: o módulo DKMS da NVIDIA não é assinado (igual ao `nvidia-image` oficial) e o
  NBFC precisa escrever no Embedded Controller, o que o *lockdown* do kernel bloqueia. Desative o
  Secure Boot.
- **/opt**: no Vanilla OS `/opt` aponta para `/var/opt`. Chrome, Mullvad e wireguird são movidos
  para `/usr/lib/opt` no build e religados via `tmpfiles.d`, então continuam vindo da imagem.
- **Nix**: o store fica em `/var/lib/nix`, montado em `/nix` no boot (`nix-bind.service`).
- **Wine 32 bits**: o Wine do Debian sid é compilado em modo WoW64, então `.exe` 32 bits rodam sem
  multiarch i386 (o i386 do sid tem binNMUs fora de sincronia com o amd64 e quebra a instalação).

## Pipeline (GitHub Actions)

`.github/workflows/build.yml`:

| Evento | O que acontece |
|---|---|
| push na `main` / execução manual | Vib gera o `Containerfile` → build e push `ghcr.io/…/vanilla-kde-nvidia:latest` e `:vAAAA.MM.DD-N` → cria a tag e a release `vAAAA.MM.DD-N` → gera a ISO (instalador apontando para a imagem daquela tag) e anexa à release |
| semanal (segunda 06:00 UTC) | só reconstrói `:latest` (atualizações do Debian, Chrome, DBeaver…) para `abroot upgrade` |

> O pacote no GHCR herda a visibilidade pública do repositório (o ABRoot e o instalador baixam a
> imagem sem login). Se um fork ficar privado: *Package settings → Change visibility → Public*.

## Créditos

- [Vanilla OS](https://github.com/Vanilla-OS): `core-image`, `desktop-image`, `nvidia-image`, `live-iso`
- [Vanilla-KDE](https://github.com/Vanilla-KDE): `base-image`, `desktop-image` (módulos Plasma)
- [nbfc-linux](https://github.com/nbfc-linux/nbfc-linux), [wireguird](https://github.com/UnnoTed/wireguird)

Licença GPL-3.0, a mesma dos projetos de origem.
