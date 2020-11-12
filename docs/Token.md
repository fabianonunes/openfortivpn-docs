# Token 0529:0600

Primeiro instale as dependências do SO:

```bash
sudo apt-get install pcscd opensc gnutls-bin openssl libpcsclite1
```

## Driver da leitora

Esse token não e compatível com o `libccid`. Portanto, é necessário instalar o driver `AKS ifdh` para que
o `pcscd` reconheça o token. Ele pode ser achado em qualquer pacote SAC para Linux sob o nome
`aks-ifdh.bundle`.

Esse `aks-ifdh.bundle` se registra para vários modelos de tokens, muitos deles com suporte ao libccid, por exemplo.
Para não sobrescrever o driver dos tokens que já são compatíveis com o libccid, deixe no `Info.plist` apenas os ids
dos tokens não suportados (nesse caso, apenas o 0529:0600).

Para instalar o driver, copie a pasta `aks-ifdh.bundle` para `/usr/lib/pcsc/drivers/`.

No bundle do driver, na pasta `Contents/Linux`, faça um link simbólico do .so para a lib versionada. Por exemplo:

```bash
# a versão pode ser outra, a depender do pacote utilizado
sudo ln -s libAksIfdh.so.10.0 libAksIfdh.so
```

Depois, reinicie o pcscd:

```bash
sudo service pcscd restart
```

Caso necessário, você pode ver os logs do pcscd se executá-lo em modo foreground:

```bash
# interrompe o serviço
sudo systemctl stop pcscd

# executa no modo foregound
/usr/sbin/pcscd --apdu --debug --foreground
```

## Driver PKCS11

O token `0529:0600` é um CardOS e precisa da respectiva lib para funcionar. No módulo SAC 8.1, as funções de CardOs vinham embutida no módulo libeToken.so. A partir da versão 9, as funções foram separadas em um módulo próprio (libcardosTokenEngine).

A versão 8.1 depende do `libhal1`, que já está obsoleto e não é encontrado em nenhum repositório atual.

Portanto, para instalar a versão 9 ou 10 do SAC, é necessário instalar, além da `libeToken.so`, a lib `libcardosTokenEngine.so`.

Para instalar a lib 8.1 do SAC, faça uma cópia do arquivo `libeToken.so.8.1` em `/usr/local/lib/` e execute:

```bash
sudo chmod 644 /usr/local/lib/libeToken.so.8.1
sudo ldconfig
```

## Verificando a instalação

```bash
opensc-tool -l
pkcs11-tool --module libeToken.so.8 -T
pkcs11-tool --module libeToken.so.8 -l -O
```

## gnutls-bin

Primeiro instale o gnutls-bin:

```bash
sudo apt-get install gnutls-bin
```

Para adicionar novos módulos, crie um arquivo .module na pasta `/etc/pkcs11/modules/` com conteúdo `module: /path/to/pkcs11.so`.

Depois de configurado o módulo, veja se os tokens são reconhecidos pelo `p11tool`:

```bash
p11tool --list-token-urls
```

## Configurar openfortivpn para usar SmartCard

> O suporte a smartcards foi adicionado na versão 1.12.0. Se precisar de uma versão mais nova, baixe em <https://packages.ubuntu.com/focal/amd64/openfortivpn/download>

Crie um arquivo que configuração com as seguintes definições:

```ini
host = «ip do gateway»
port = «porta do gateray»
trusted-cert = «incluir caso haja certificado não reconhecido pelo so»
# o user-cert pode ser apenas «pkcs11:» ou pode ser passado
# a URL completa do token (conforme output do comando p11tool --list-token-urls)
# casa haja mais de um token disponível
user-cert = pkcs11:

# Antes do openfortivpn 1.14, era necessário passar quaisquer valores para os campos
# `username` e `password`. Da 1.14 em diante, esses campos deve ser vazios ou removidos
# caso a VPN não exija credenciais de usuário/senha além do certificado.
# username = none
# password = none
```
