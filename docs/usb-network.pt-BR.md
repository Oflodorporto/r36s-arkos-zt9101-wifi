# Recuperação por USB: console ↔ PC Windows

[English](usb-network.en.md) · [Guia principal](../README.pt-BR.md)

A rede USB permite acessar um console sem Wi-Fi funcional. O console funciona
como uma placa de rede USB; o Windows reconhece um adaptador RNDIS. Esse
caminho é separado da instalação do driver do dongle Wi-Fi.

No reparo usamos **USB Network Mode, de ctgl1987**, cabo de dados, DTB próprio
verificado, Windows/RNDIS e SSH. A versão da ferramenta usada está em
`third_party/usb-network/`, com a licença MIT original. Projeto de origem:
https://github.com/ctgl1987/arkos-usb-network-mode .

## Antes de conectar

- Use a **porta USB-C OTG/de dados**, não a porta exclusiva de carregamento.
- O cabo precisa transmitir dados. Carregar não comprova isso.
- Preserve os arquivos de boot e o DTB do próprio console.
- Execute primeiro a verificação de compatibilidade da ferramenta. Ela confere
  módulo gadget, UDC disponível, modo da controladora e ligação de dados/VBUS.
  Em alguns clones, a fiação não permite esse recurso por software.

## Descobrir qual DTB está ativo

Leia `/boot/boot.ini`, os seletores de painel e o arquivo realmente escolhido
no boot. Não suponha que o DTB diretamente na raiz de `/boot/` seja o usado:
no nosso R36S, era um arquivo dentro de `ScreenFiles/Panel 4/`. Outro console
pode usar caminho e painel diferentes. Não copie o DTB de outro aparelho só
porque ambos têm R36S escrito na carcaça.

No RK3326 testado, a controladora era `/usb@ff300000` e esse caminho de
recuperação precisou de `dr_mode=peripheral`. A ferramenta opcional abaixo
altera **apenas essa propriedade**, verifica o backup e preserva as demais
configurações de tela e de clock do cartão:

```sh
sudo bash tools/dtb-usb-mode.sh '/caminho/absoluto/SEU-DTB-ATIVO.dtb' peripheral
```

Confirme caminho e controladora antes de usar. Se `fdtget` não encontrar o
nó/propriedade, pare. Anote o modo anterior exibido pela ferramenta e reinicie.

## Modo Universal: arquivos e SSH

1. Copie `third_party/usb-network/USB Network Mode.sh` para Tools/Options usando
   o leitor de cartão ou o acesso de rede já disponível.
2. Abra a ferramenta, faça a verificação e selecione **Universal**.
3. Conecte o cabo de dados da porta OTG do console ao PC.
4. Aguarde o Windows reconhecer a placa Ethernet RNDIS. Se não reconhecer,
   confira o Gerenciador de Dispositivos e o relatório da ferramenta antes de
   instalar um driver aleatório ou trocar novamente o DTB.
5. Nesse modo, o console usa `10.44.44.1` e fornece um IP USB ao PC por DHCP.
6. Pelo Terminal do Windows ou WSL, conecte com seu usuário do console:

```sh
ssh SEU_USUARIO@10.44.44.1
scp r36s-zt9101-r2-install.tar.gz SEU_USUARIO@10.44.44.1:/home/SEU_USUARIO/
```

Confira a identidade do console ao aceitar uma nova chave SSH. Se o IP mudou,
compare a chave já confiável; não desative a verificação de identidade. A
ferramenta original documenta credenciais de fábrica: use as que configurou e
nunca envie senhas para um chat de IA ou uma issue.

Nosso teste confirmado do modo Universal teve console em `10.44.44.1`, PC com
IP recebido por DHCP nessa rede, ping e SSH funcionando. Não foi necessário
compartilhar a internet do PC para acessar e transferir arquivos.

## Internet pelo PC: outro modo

No modo **Internet**, o console solicita um endereço ao PC. Este procedimento
é documentado pelo autor da ferramenta e deve ser distinguido do teste
Universal descrito acima.

Ative o modo Internet e conecte o cabo **antes** de selecionar a placa no
Windows. Abra `ncpa.cpl`, entre nas propriedades da placa do PC que já tem
internet, abra **Compartilhamento**, habilite o compartilhamento da conexão e
selecione a placa RNDIS do console. Execute o modo Internet novamente e leia o
IP informado. Não suponha um endereço fixo escolhido pelo Windows. Confira
rota, DNS e acesso HTTPS.

## Voltar ao dongle Wi-Fi

Desligue pelo menu. Restaure o modo original do DTB (`otg` ou `host`, conforme
anotado para o aparelho), reinicie e desconecte o cabo do PC antes de usar o
dongle:

```sh
sudo bash tools/dtb-usb-mode.sh '/caminho/absoluto/SEU-DTB-ATIVO.dtb' otg
```

Use `otg` nesse exemplo somente se era o modo original funcional. Não
fornecemos um DTB substituto nem alteramos o painel da tela automaticamente.
Os serviços opcionais de Samba e navegador são separados do SSH; não precisam
ser ativados apenas para transferir o pacote do driver.
