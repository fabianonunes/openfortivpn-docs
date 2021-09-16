# FortiClient VPN no Linux

## 1. Preparo para acesso via login e senha

> Se você utiliza token, pule para a seção 2.

### 1.1. Dependências

Instale o cliente do FortiClientVPN:

```bash
sudo apt-get install openfortivpn
```

### 1.2. Configuração do openfortivpn

Após a instalação crie o arquivo `~/.config/openfortivpn.cfg` com o seguinte conteúdo:

```ini
host = IP do gateway
port = Porta do gateway
username = Seu nome de usuário
trusted-cert = Digest SHA256 do certificado, veja a seção 3.1
```

Para se conectar à VPN, execute:

```bash
sudo openfortivpn -c ~/.config/openfortivpn.cfg
```

## 2. Preparo para acesso via Token

### 2.1. Dependências

Instale as dependências do SO:

```bash
sudo apt-get install pcscd gnutls-bin libengine-pkcs11-openssl openfortivpn
```

### 2.2. Driver do Token

Baixe o driver do token no site do Serpro e instale o `.deb` respectivo à arquitetura do seu sistema operacional:

```bash
wget 'http://repositorio.serpro.gov.br/drivers/safenet/SafeNetAuthenticationClient-9.1_Linux_Ubuntu-RedHat(32-64bits).zip'
unzip 'SafeNetAuthenticationClient-9.1_Linux_Ubuntu-RedHat(32-64bits).zip'
sudo dpkg -i SafenetAuthenticationClient-BR-10.0.37-0_amd64.deb
```

Caso não exista, crie o diretório `/etc/pkcs11/modules` e dentro dele crie o arquivo `eToken.module` com o seguinte conteúdo:

```text
module: /usr/lib/libeToken.so
```

### 2.3. URL do Certificado

Insira o token na porta USB e aguarde alguns segundos. Em seguida, identifique a **URL do token**:

```bash
# selecione a URL do fabricante de seu token (no comando abaixo, é a última linha):
$ p11tool --list-token-urls
pkcs11:model=p11-kit-trust;manufacturer=PKCS%2311%20Kit;serial=1;token=System%20Trust
pkcs11:model=eToken;manufacturer=SafeNet%2c%20Inc.;serial=XXXXXXXXX;token=eToken
```

Depois guarde a **URL do certificado** para ser utilizado na próxima seção. Provavelmente,
será o último item da lista.

```bash
$ p11tool --list-all-certs $URL_DO_TOKEN # a URL_DO_TOKEN vc pegou no último comando
> (...)
> # podem aparecer vários resultados. Escolha o certificado mais adequado.
> Object 2:
>     URL: pkcs11:model=eToken;manufacturer=SafeNet%2c%20Inc.;serial=(...);token=eToken;id=(...);object=te-VPNSmartcardLogon-(...);type=cert
>     Type: X.509 Certificate
>     Label: te-VPNSmartcardLogon-(...)
>     ID: 47:5b:0d:8e:9f:46:49:25
$
```

### 2.4. Configuração do openforticlient

Após a instalação, crie o arquivo `~/.config/openfortivpn.cfg` com o seguinte conteúdo:

```ini
host = IP do gateway
port = Porta do gateway
trusted-cert = Digest sha256 do certificado, veja a seção 3.1
user-cert = URL do certificado obtido na seção anterior
```

#### 2.4.1 Passagem automática do PIN

É possível passar o PIN do token diretamente ao `openfortivpn` para não precisar digitá-lo
a cada conexão. Basta adicionar `;pin-value=xxxx` ao final da URI do certificado.

O uso do `pin-value` pode ter consequências de segurança, afinal o PIN do token ficará armazenado em um
arquivo de texto plano.

#### 2.4.2 Configuração do OpenSSL

Crie o arquivo `~/.config/ssl.conf` com o seguinte conteúdo:

```ini
openssl_conf = default_conf
[default_conf]
ssl_conf = ssl_sect
[ssl_sect]
system_default = system_default_sect
[system_default_sect]
CipherString = DEFAULT@SECLEVEL=1
```

### 2.5. Conecte-se à VPN

Para se conectar à VPN, execute:

```bash
sudo OPENSSL_CONF=$HOME/.config/ssl.conf openfortivpn -c ~/.config/openfortivpn.cfg
```

## 3. Resolução de problemas

### 3.1. trusted-cert

O `trusted-cert` é o identificador do certificado do servidor da VPN (nada mais que o digest sha256
da representação DER do certificado):

```bash
# Substitua «ip:porta» pelos dados reais do gateway.
echo | openssl s_client -showcerts -connect ip:porta 2>/dev/null | \
  openssl x509 -outform der | \
  openssl dgst -sha256
```

Passe o hash resultante para o atributo `trusted-cert` do arquivo de configuração,
mas antes **confirme o valor com alguém de confiança**!

### 3.3. Ubuntu >= 20.04

#### 3.3.1. CRYPTO/Crypto.c:258: init_openssl_crypto: Assertion `lib' failed

A versão `10.0.37` do driver SafeNet exige uma versão da libssl dentro do intervalo
fixo `>=0.9.8 || <=1.0.1`. Porém, no Ubuntu >=20.04, a libssl está na versão `1.1`.
Neste caso específico, a compatibilidade não foi comprometida e é preciso "enganar"
o driver para que ele encontre a biblioteca correta. Para isso, crie um link apontando
para a libssl do Ubuntu:

```bash
sudo ln -s /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 /usr/lib/x86_64-linux-gnu/libcrypto.so
```

#### 3.3.2. Segmentation fault

> Ubuntu 20.04

A versão `1.12.0` do openfortivpn retorna `Segmentation fault` logo após a entrada do PIN.
Este problema pode ser resolvido atualizando o pacote para uma versão mais nova ou removendo
o atributo `object=...` da URL do certificado.

#### 3.3.3. Failed to enumerate slots

> Ubuntu 21.10

Este bug só acontece em distribuições que possuam o PKCS11 do OpenSC instalado.

A versão `0.21.0` do OpenSC introduziu um bug no momento de informar o status do token para a aplicação:

```text
Failed to enumerate slots
PKCS11_get_private_key returned NULL
cannot load Private Key from engine
```

O bug foi provocado pelo commit [1bb2547a](https://github.com/OpenSC/OpenSC/commit/1bb2547abca12f3ce22d48c3c171ea5e44ab4c4a)
e revertido em [7a090b99](https://github.com/OpenSC/OpenSC/commit/7a090b994e70a63a59825142dd6182332931bcdd).

Para resolver o problema, pode-se utilizar uma das três alternativas:

- Caso não seja utilizado, remova o pacote `opensc-pkcs11`:

  ```bash
  sudo apt-get purge opensc-pkcs11
  ```

- Caso o OpenSC seja utilizado mas não precise de integração com o `p11-kit`, desabilite seu módulo:

  ```bash
  sudo rm /usr/share/p11-kit/modules/opensc-pkcs11.module
  ```

- Caso o OpenSC não possa ser removido, compile uma nova versão:

  - Pode-se compilar diretamente dos fontes, contanto que se utilize uma versão com o patch [7a090b99](https://github.com/OpenSC/OpenSC/commit/7a090b994e70a63a59825142dd6182332931bcdd) aplicado.
  - Em vez de compilar diretamente dos fontes, recomendo [construir um novo pacote](https://help.ubuntu.com/community/UpdatingADeb)
    aplicando o patch [7a090b99](https://github.com/OpenSC/OpenSC/commit/7a090b994e70a63a59825142dd6182332931bcdd)
