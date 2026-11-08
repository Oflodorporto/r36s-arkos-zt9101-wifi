# Como sua IA pode ajudar

[English](ai-assistance.en.md) · [Guia principal](../README.pt-BR.md)

A IA pode interpretar registros, comparar código e headers do kernel, preparar
correções, compilar e ajudar a validar a instalação. Ela precisa de evidência
real do aparelho e de um caminho autorizado até o PC/console. Um chat comum
não ganha acesso automático ao cartão nem aos IPs da sua rede.

## Caminho prático

1. Identifique VID:PID USB, kernel/arquitetura e hash do Image.
2. Preserve um adaptador funcional ou estabeleça a recuperação USB. Ative o
   serviço remoto e use SSH. Neste reparo usamos Desktop Commander autorizado
   pelo usuário no Windows, WSL Ubuntu e SSH; outro terminal confiável serve.
3. Entregue à IA este repositório e um diagnóstico **revisado**. Comece pela
   leitura. Senhas, chaves SSH e tokens ficam fora do chat.
4. Peça conferência da ABI do kernel, backup e teste com espera limitada. O
   mesmo número de versão não comprova que os headers sejam compatíveis.
5. Confira as etapas: módulo → firmware → interface → busca → autenticação →
   IP → HTTPS → reinicialização. Sucesso em uma etapa não comprova a seguinte.
   O usuário faz as trocas físicas de cabo e dongle.
6. Se houver Oops no kernel, preserve o registro e corrija a causa antes de
   repetir. Um botão Voltar não desfaz uma falha do kernel.

Prompt sugerido:

> Ajude-me a diagnosticar o ZT9101 USB 350b:9101 usando este repositório. Leia
> primeiro a tabela de compatibilidade, notas técnicas e AGENTS.md. Confira
> o hash real do meu Image e a identidade USB antes de alterar arquivos.
> Preserve jogos, saves, drivers funcionais e o DTB ativo do meu aparelho.
> Explique cada mudança e a restauração. Diferencie carregamento do módulo,
> interface, IP e internet funcionando. Use registros revisados e não publique
> credenciais nem dados que identifiquem minha rede.

Para recompilar, forneça fonte/configuração reais do kernel e informações do
compilador, além do modelo do console. Peça a comparação da tabela de callbacks
e das funções exigidas pelo módulo. Este reparo precisou de
`CONFIG_NL80211_TESTMODE=y` no kernel testado.

## Ferramentas utilizadas

| Ferramenta | Função |
| --- | --- |
| ChatGPT / Codex | Análise do código/logs, correções, scripts e documentação |
| Desktop Commander | Terminal e arquivos no Windows, com autorização do usuário |
| WSL Ubuntu | Git, compilação cruzada e cliente SSH |
| SSH / SCP | Diagnóstico do console e transferência de arquivos |
| GCC 13.3.0 e GNU make | Compilação do módulo aarch64 |
| nm, readelf, objdump e SHA-256 | Localizar falhas, comparar ABI e conferir arquivos |
| NetworkManager / nmcli | Conferir interface, redes e endereço IPv4 |
| USB Network Mode / RNDIS | Recuperação por cabo sem depender do Wi-Fi |
| dtc / fdtget / fdtput | Inspecionar o DTB ativo e alterar o modo USB verificado |

A resposta da IA é uma proposta até ser sustentada por registros e testes no
aparelho. O projeto registra os resultados e os autores originais; não atribui
à IA a criação integral do driver.
