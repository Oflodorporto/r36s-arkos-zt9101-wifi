# Correção Wi-Fi ZT9101 para R36S / R36SH com ArkOS

**Português do Brasil · [English](README.md)**

Correções de compatibilidade para o dongle **ZTop ZT9101 `350b:9101`**, testadas
na versão específica do **ArkOS com Linux 4.4.189 aarch64** descrita abaixo.
O projeto inclui o módulo R2 testado, código-fonte correspondente, instalador,
restauração, conexão USB com o PC e um guia para sua IA ajudar no diagnóstico.

Este trabalho nasceu da recuperação de dois consoles da família. Rodolfo fez
os testes físicos; ChatGPT/Codex ajudou a analisar os registros do kernel,
adaptar o código e compilar. O driver do chip é da ZTop e da comunidade
upstream: os [créditos e licenças](THIRD_PARTY.md) fazem parte da contribuição.

## O que foi corrigido

1. **Falha ao inicializar o USB:** o código acessava um ponteiro inválido em
   `zt_endpoint_init`. A R2 consulta o descritor pela API USB do kernel e valida
   tamanho, ponteiros e limites das listas de endpoints.
2. **Travamento do serviço Wi-Fi:** a compilação sem
   `CONFIG_NL80211_TESTMODE` deslocava a tabela `cfg80211_ops`. Uma solicitação
   de `flush_pmksa` chegava à função `cancel_remain_on_channel`, com argumento
   incompatível. O perfil de compilação fornecido corrige esse alinhamento.
3. **Diagnóstico dizendo que não criou interface:** esse driver pode não
   publicar o vínculo `device/driver` no sysfs. A ausência dele não prova que
   `wlan0` deixou de existir. A validação distingue carregamento, interface,
   associação ao roteador, obtenção de IP e acesso à internet.

## Compatibilidade

| Item | Escopo validado |
| --- | --- |
| Adaptador | ZTop ZT9101, VID:PID `350b:9101` |
| Console | R36S: validação direta de rede e reinicialização; R36SH: instalação/carregamento/descarregamento conferidos e Wi-Fi após troca do dongle confirmado pelo proprietário |
| Sistema | aarch64, kernel `4.4.189`, SMP, descarregamento de módulos |
| SHA-256 do Image testado | `acf57a15f6aecf08dc9dea98eaaf88aa355aba1193c67d13b9805f7a416df40b` |
| SHA-256 do módulo R2 | `50657888964e79889ccbe17823d4b9cf83bb0b1deb9437b6fae7d764c92cfc78` |
| Evidência no R36S | Firmware, interface, WPA, IP, SSH, HTTPS e reconexão automática após reiniciar |
| Outros kernels, dArkOS e outras placas/clones | Não validados por estes testes; precisam de compilação e verificação próprias |

**Ter o mesmo número de kernel não basta.** O instalador recusa um
`/boot/Image` com hash diferente. Não force um driver MediaTek/Realtek neste ID
USB. O nome na carcaça não identifica sozinho kernel, painel ou ligação USB.

## Placas testadas e o caso de Wi-Fi Off

| Unidade de teste | Identificação física | Evidência e limites |
| --- | --- | --- |
| R36S vertical | Inscrição visível na PCB fotografada pelo proprietário: **`R36S-V12`**, data **`2023-08-18`** | O Wi-Fi foi recuperado nesta unidade. A inscrição identifica a PCB visível na foto; não comprova, sozinha, a revisão de todas as placas internas do console. A configuração de tela usada foi Panel 4. |
| R36SH / R36S-H horizontal | Modelo identificado; **revisão exata da PCB ainda não confirmada por inscrição legível disponível** | Instalação da R2 e carregamento/descarregamento do módulo conferidos; Wi-Fi após troca dos dongles confirmado pelo proprietário. O modelo da carcaça não deve ser tratado como revisão de PCB. |

O console vertical apresentava **Wi-Fi Off**, lista de redes vazia e
travamentos no aplicativo Wi-Fi/menu. O proprietário relatou que **o mesmo
console e dongle Realtek funcionaram com o cartão já configurado do outro
console**, enquanto o cartão original não conectava. Essa comparação apontou
para o software/configuração de inicialização no cartão; ela não sustentava
declarar a unidade definitivamente incapaz de usar Wi-Fi USB. Os testes de
rede posteriores confirmaram a recuperação no console vertical.

O outro adaptador testado foi o **Realtek RTL8188FTV, USB `0bda:f179`**, com
driver `rtl8188fu`. **O instalador ZTop R2 deste repositório é destinado ao
`350b:9101`; ele não instala driver Realtek.** O Realtek está documentado como
comparação e caminho de recuperação que funcionou, sem afirmar que todo
adaptador com esse nome ou toda PCB marcada R36S-V12 funcionará com o pacote.

Se um dongle Realtek aparentemente compatível continua mostrando Wi-Fi Off,
compare **ID USB, Image exato do kernel, módulo correspondente, bloqueios/
configurações e DTB ativo/modo USB**. Depois separe detecção USB, criação de
interface, associação à rede e DHCP. Ter o mesmo número de kernel ou o mesmo
nome na carcaça não basta para comprovar compatibilidade. Uma busca de redes
vazia, sozinha, não identifica uma placa defeituosa. Estes resultados registram
as unidades testadas, sem prometer suporte universal ou uma causa única para
toda falha de Wi-Fi.

## Instalação

Baixe **[r36s-zt9101-r2-install.tar.gz](r36s-zt9101-r2-install.tar.gz)** deste repositório, extraia e copie a
pasta completa `ztop-r2` para `/roms/tools/`. Use um leitor de cartão ou o
[caminho de rede por USB](docs/usb-network.pt-BR.md). Mantenha o acesso que já
funciona até transferir os arquivos.

Execute pelo SSH ou gerenciador de arquivos do console:

```sh
cd /roms/tools/ztop-r2
bash tools/install.sh --check-package
bash tools/install.sh --dry-run
bash Install-ZTop.sh
```

O instalador verifica arquivos e kernel, cria backup em
`/var/backups/r36s-zt9101/`, instala módulo/firmware/configuração, remove o
bloqueio temporário conhecido do ZTop e executa `depmod`. Ele não descarrega o
adaptador em uso, não reinicia sozinho e não altera jogos, saves, driver
Realtek, Image do kernel ou DTB da tela.

Desligue pelo menu, conecte o ZTop à **porta OTG/de dados** e ligue. Abra Wi-Fi
e escolha a rede caso a conexão não seja automática. Consulte **Network Info**
para ver o IP atual. Depois de instalado, o teste experimental de 40 segundos
não é necessário.

No nosso adaptador, o driver usou um MAC gerado e o IP atribuído pelo roteador
mudou entre inicializações. Confira o endereço atual: uma mudança de IP não
significa, por si só, perda de conexão.

## Verificação e restauração

```sh
ip -brief address
nmcli device status
python3 tools/diagnose.py --scan
```

Confira acesso SSH e uma requisição HTTPS. Reinicie e confirme a reconexão
automática. O retorno 0 do `insmod` sozinho não comprova Wi-Fi funcionando.
Os diagnósticos limitam a espera de subprocessos, mas não recuperam um kernel
completamente travado.

Para restaurar:

```sh
bash tools/rollback.sh /var/backups/r36s-zt9101/SEU-BACKUP
```

Reinicie após restaurar e preserve o backup. Se não houver rede, use o Realtek
que já funcionava ou a recuperação USB; o instalador preserva esses caminhos.

## Entender, compilar e contribuir

- [Evidências técnicas e compilação](docs/technical-notes.pt-BR.md)
- [Cabo USB, Windows/RNDIS, SSH e compartilhamento de internet](docs/usb-network.pt-BR.md)
- [Como sua IA pode ajudar](docs/ai-assistance.pt-BR.md)
- [Créditos e licenças](THIRD_PARTY.md) · [compartilhamento seguro dos registros](SECURITY.md)

O fonte upstream completo e fixado está em `sources/`; nossas alterações em
`patches/`; a configuração de compilação em `config/`. O pacote de instalação
também acompanha o fonte correspondente. Relate ID USB, hash do kernel, perfil
de compilação e evidências revisadas ao contribuir. Não marque placas ainda
não testadas como compatíveis.

Mantenedor: **Rodolfo Porto dos Santos — [Oflodorporto](https://github.com/Oflodorporto)**.
Contribuição independente, sem caráter oficial de ArkOS, ZTop ou OpenAI.
