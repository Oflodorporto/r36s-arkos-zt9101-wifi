# Evidências técnicas e compilação

[English](technical-notes.en.md) · [Guia principal](../README.pt-BR.md)

## Identidade do sistema testado

- Linux `4.4.189 #3 SMP Wed Oct 13 23:24:26 EDT 2021`, aarch64.
- SHA-256 do Image: `acf57a15f6aecf08dc9dea98eaaf88aa355aba1193c67d13b9805f7a416df40b`.
- Vermagic: `4.4.189 SMP mod_unload aarch64`.
- Kernel: christianhaitian/linux, commit
  `d8402159c04b1044106b4f27b7ed7c22ed09228f` (rg351).
- Driver upstream: yjun123/ZT9101_vendor_linux_driver, commit
  `c5a28ea78a01a40f24b7e5ab3049468bf74e16f8`.
- Perfil: `rg351p_tweaked_defconfig`, com
  `CONFIG_NL80211_TESTMODE=y` e `CONFIG_LOCALVERSION_AUTO` desabilitado.
- Compilador do módulo: GCC aarch64-linux-gnu 13.3.0 do Ubuntu. O kernel
  original usa Linaro GCC 6.3.1; não afirmamos que esses compiladores sejam
  iguais. Carregamento, descarregamento e comportamento físico foram
  verificados separadamente.

A configuração completa fornecida é a referência de reprodução. Um arquivo
com ArkOS no nome não é necessariamente o perfil do kernel em execução.

## Primeira falha: ponteiro da configuração USB

No primeiro teste instrumentado, `insmod` terminou com sinal 11. Um Oops de
NULL+4 apontou para `zt_endpoint_init+0x38`: o código lia `bNumInterfaces`
através de `usb_device->actconfig`. O patch consulta o descritor pela função
`usb_get_descriptor`, valida o retorno e os limites das listas de endpoints.
Também lê o tamanho do pacote bulk por `wMaxPacketSize`, com conversão de
endianness.

Depois disso, os logs mostraram endpoints, energização USB, transferência dos
dois firmwares e registro da interface. Essas etapas ainda não comprovavam
uma conexão de rede completa.

## Segunda falha: tabela de callbacks

A R1 criava a interface, mas derrubava `wpa_supplicant` com um Oops em
`cfg80211_cancel_remain_on_channel_cb+0x28`. A função interpretava um argumento
`net_device` como `wireless_dev`.

O código de máquina do kernel carregava a função pelo deslocamento
**456 / 0x1c8**, passando `wiphy` e `net_device`. Sem as entradas de
`CONFIG_NL80211_TESTMODE`, esse endereço escolhia
`cancel_remain_on_channel`. Habilitada a opção, constantes `offsetof`
compiladas confirmaram `flush_pmksa` em **0x1c8**, compatível com a solicitação
do kernel.

Os módulos nativos exfat/gpio_keys e o módulo corrigido também coincidiram nas
posições das funções de entrada/saída: **0x170 / 0x278**. Uma compilação
intermediária, com saída desalinhada, carregava como permanente e foi
descartada. Essa coincidência é uma evidência útil, mas não comprova toda a
ABI: o teste físico continua necessário.

A R2 fez busca, associação e instalação de chaves WPA sem repetir o Oops.
Depois corrigimos o diagnóstico, que dependia de um vínculo sysfs ausente
nesse driver. No R36S foram confirmados IP, SSH, HTTPS e reconexão automática
após reiniciar. O estado de cada aparelho está na tabela do README e não deve
ser deduzido apenas da carcaça.

## Compilar em Linux x86-64

O host testado foi WSL Ubuntu 24.04. Instale as dependências usuais:

```sh
sudo apt update
sudo apt install build-essential gcc-aarch64-linux-gnu bc flex bison libssl-dev curl patch
bash tools/build-driver.sh
```

O script baixa o kernel fixado, extrai o fonte do driver fornecido, aplica o
patch, prepara os headers pela configuração salva e compila o módulo. O
arquivo do kernel não inclui o submódulo externo exFAT; um Kconfig mínimo é
criado **somente para preparar headers de módulo externo**, nunca para
compilar/instalar um Image de kernel.

Não é instalado nem compilado um novo kernel ou DTB. Passamos `CC`
explicitamente para não depender do alias `python` do antigo launcher de
compilação. O hash do binário recompilado pode variar conforme host,
compilador e metadados do caminho de build. O instalador público aceita
somente o binário testado: outra compilação precisa de revisão própria de ABI,
teste físico e manifesto de distribuição.

## Cartão e limites conhecidos

O cartão original também apresentava timeouts MMC. No DTB ativo verificado,
reduzir o clock de 150 MHz para 50 MHz eliminou esses erros nas leituras
selecionadas repetidas e nos boots seguintes. Foi uma medida específica de
estabilidade, não uma certificação completa de saúde/capacidade. O instalador
não aplica essa mudança. Não execute fsck com reparação na raiz montada.

A leitura do MAC na efuse do adaptador falhou; o fallback do fornecedor gerou
MACs diferentes, permitindo mudança de IP por DHCP. Provisionamento de MAC
fixo, suspensão/retomada, roaming e benchmark de velocidade não foram
validados. Preserve esses limites ao divulgar o resultado.
