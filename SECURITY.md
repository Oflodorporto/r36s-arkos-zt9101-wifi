# Reporting safely / Relatos seguros

Before posting a diagnostic report, remove Wi-Fi passwords, SSH private keys,
access tokens, personal paths, hostnames, SSIDs, machine identifiers and MAC/IP
addresses that you do not want public. Never upload an entire SD-card image.
Only the maintainer's sanitized technical evidence belongs in this repository.

Antes de publicar um diagnóstico, remova senhas de Wi-Fi, chaves SSH, tokens,
caminhos pessoais, nomes de rede/aparelho e identificadores que não queira
divulgar. Não envie uma imagem completa do cartão. Use os campos técnicos do
modelo de issue; nunca inclua credenciais.

Use SSH on a trusted local/USB network. The upstream USB helper documents
factory-default credentials; configure your own credentials before wider use.
No router port forwarding or public remote-access service is needed here.
