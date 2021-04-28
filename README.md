# FortiClient VPN no Linux

## 1. Preparo para acesso via login e senha

> Se você utiliza token, pule para a seção 2.

### 1.1. Dependências

<details>
<summary>1.1.1 Ubuntu 18.04 e mais recentes</summary>

Instale o cliente do FortiClientVPN:

```bash
sudo apt-get install openfortivpn
```

</details>

<details>
<summary>1.1.2 Ubuntu 16.04 e mais antigos</summary>

Compile e instale o openfortivpn:

```bash
sudo apt-get install gcc automake autoconf libssl-dev
wget https://github.com/adrienverge/openfortivpn/archive/v1.12.0.tar.gz -O - | tar xz
cd openfortivpn-1.12.0
./autogen.sh
./configure --prefix=/usr/local --sysconfdir=/etc
make
sudo make install
```

</details>

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

<details>
<summary>2.1.1. Ubuntu 20.04 e mais recentes</summary>

Instale as dependências do SO:

```bash
sudo apt-get install pcscd gnutls-bin libengine-pkcs11-openssl openfortivpn
```

</details>

<details>
<summary>2.1.2. Ubuntu 18.04 (64 bits)</summary>

Primeiro instale as dependências do SO:

```bash
sudo apt-get install pcscd gnutls-bin libengine-pkcs11-openssl
```

O pacote `openfortivpn` do Ubuntu 18.04 está na versão 1.6.0, que não é compatível com smartcards. Você pode baixar e instalar o `.deb` do Ubuntu 20.04. Sua instalação é segura, pois depende apenas dos pacotes `libc6 >=2.15` e `libssl1.1 >=1.1.0`, ambos compatíveis com Ubuntu 18.04.

```bash
# URL obtida a partir da página do pacote: https://packages.ubuntu.com/focal/openfortivpn
wget http://mirrors.kernel.org/ubuntu/pool/universe/o/openfortivpn/openfortivpn_1.12.0-1_amd64.deb
sudo apt-get install -f ./openfortivpn_1.12.0-1_amd64.deb
```

</details>

<details>
<summary>2.1.3. Ubuntu 18.04 (32 bits)</summary>

Instale as dependências do SO:

```bash
sudo apt-get install pcscd gnutls-bin libengine-pkcs11-openssl pkgconf libssl-dev build-essential git-core autoconf
```

Não há pacotes do `openfortivpn` pré-compilados para o Ubuntu 18 de 32 bits. Então, precisamos compilar a partir do
código fonte:

```bash
wget https://github.com/adrienverge/openfortivpn/archive/v1.15.0.tar.gz
tar xf v1.15.0.tar.gz
cd openfortivpn-1.15.0
./autogen.sh
./configure --prefix=/usr/local --sysconfdir=/etc
make
sudo make install
```

</details>

<details>
<summary>2.1.4. Ubuntu 16.04 (32 e 64 bits)</summary>

Instale as dependências do SO:

```bash
sudo apt-get install pcscd gnutls-bin p11-kit pkgconf libssl-dev build-essential git-core autoconf
```

Desinstale a `libp11` e a `engine-pkcs11` do Ubuntu, caso estejam instaladas:

```bash
sudo apt-get purge libp11-2 libengine-pkcs11-openssl
```

Compile e instale a `libp11` a partir código fonte:

```bash
wget https://github.com/OpenSC/libp11/releases/download/libp11-0.4.11/libp11-0.4.11.tar.gz
tar xf libp11-0.4.11.tar.gz
cd libp11-0.4.11
# no comando abaixo, troque «x86_64» por «i386» caso o SO seja de 32 bits
./configure --with-pkcs11-module=/usr/lib/x86_64-linux-gnu/p11-kit-proxy.so
make
sudo make install
```

Compile e instale o OpenFortiVPN:

```bash
wget https://github.com/adrienverge/openfortivpn/archive/v1.15.0.tar.gz
tar xf v1.15.0.tar.gz
cd openfortivpn-1.15.0
./autogen.sh
./configure --prefix=/usr/local --sysconfdir=/etc
make
sudo make install
```

</details>

### 2.2. Driver do Token

Baixe o driver do token no site do Serpro e instale o `.deb` respectivo à arquitetura do seu sistema operacional:

```bash
wget 'http://repositorio.serpro.gov.br/drivers/safenet/SafeNetAuthenticationClient-9.1_Linux_Ubuntu-RedHat(32-64bits).zip'
unzip 'SafeNetAuthenticationClient-9.1_Linux_Ubuntu-RedHat(32-64bits).zip'
# no comando abaixo, troque «amd64» por «i386» caso o SO seja de 32 bits
sudo dpkg -i SafenetAuthenticationClient-BR-10.0.37-0_amd64.deb
```

Desative o daemon `SACSrv` que foi instalado junto com o driver, pois não tem utilidade para a conexão à VPN:

```bash
sudo systemctl disable SACSrv
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

### 2.5. Conecte-se à VPN

Para se conectar à VPN, execute:

```bash
sudo openfortivpn -c ~/.config/openfortivpn.cfg
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

### 3.2. Ubuntu 18.04 de 32 bits

No Ubuntu 18.04 de 32 bits, o OpenSSL procura pelas engines na pasta `/usr/lib/i386-linux-gnu/engines-1.1/`, porém
o pacote `libengine-pkcs11-openssl` instala a biblioteca em `/usr/lib/i686-linux-gnu/engines-1.1/`. Esse equívoco
no empacotamento resulta no seguinte erro:

```text
Could not load pkcs11 Engine: error:2606A074:engine routines:ENGINE_by_id:no such engine
```

Para corrigir, basta fazer um link da biblioteca na pasta correta:

```bash
sudo ln -s /usr/lib/i686-linux-gnu/engines-1.1/pkcs11.so /usr/lib/i386-linux-gnu/engines-1.1/
```

### 3.3. Ubuntu >= 20.04

#### 3.3.1. CRYPTO/Crypto.c:258: init_openssl_crypto: Assertion `lib' failed

A versão `10.0.37` do driver SafeNet exige uma versão da libssl dentro do intervalo
fixo `>=0.9.8 || <=1.0.1`. Porém, no Ubuntu >=20.04, a libssl está na versão `1.1`.
Neste caso específico, a compatibilidade não foi comprometidade e é preciso "enganar"
o driver para que ele encontre a biblioteca correta. Para isso, crie um link apontando
para a libssl do Ubuntu:

```bash
sudo ln -s /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 /usr/lib/x86_64-linux-gnu/libcrypto.so
```

#### 3.3.2. routines:SSL_CTX_use_certificate:ee key too small

No Ubuntu >= 20.04, a versão do OpenSSL foi compilada com a opção `-DOPENSSL_TLS_SECURITY_LEVEL=2`.
Nesse nível de segurança, chaves de 1024 bits são consideradas inseguras e são desativadas por padrão. Ao
tentar acessar o `openfortivpn` com uma chave insegura, você pode receber a seguinte mensagem de erro:

```text
ERROR:  PKCS11 SSL_CTX_use_certificate: error:140AB18F:SSL routines:SSL_CTX_use_certificate:ee key too small
```

Nesse caso, é preciso afrouxar o nível de segurança para permitir conexões com chaves de 1024 bits. Esse ajuste pode
ser feito diretamente no arquivo `/etc/ssl/openssl.cnf` (não recomendável, pois afetaria o `openssl` globalmente) ou
num arquivo de configuração próprio para o `openfortivpn`.

Crie um arquivo com o seguinte conteúdo:

```ini
openssl_conf = default_conf

[default_conf]
ssl_conf = ssl_sect

[ssl_sect]
system_default = system_default_sect

[system_default_sect]
CipherString = DEFAULT@SECLEVEL=1
```

Agora basta passar o _path_ **absoluto** desse arquivo para a variável de ambiente `OPENSSL_CONF` ao
executar o `openfortivpn`:

```bash
sudo OPENSSL_CONF=/path_configuracoes_openssl.cnf openfortivpn -c ~/path_configuracoes_openfortivpn.cfg
```

### 3.4. Ubuntu 20.04

#### 3.4.1. Segmentation fault

A versão `1.12.0` do openfortivpn retorna `Segmentation fault` logo após a entrada do PIN.
Este problema pode ser resolvido atualizando o pacote para uma versão mais nova ou removendo
o atributo `object=...` da URL do certificado.

### 3.5. Ubuntu 21.04

#### Failed to enumerate slots

> Este bug só acontece em distribuições que possuam o PKCS11 do OpenSC instalado.

A versão `0.21.0` do OpenSC introduziu um bug no momento de informar o status do token para a aplicação.
Com isso, o seguinte erro é apresentado:

```text
Failed to enumerate slots
PKCS11_get_private_key returned NULL
cannot load Private Key from engine
```

O bug foi provocado pelo commit [1bb2547a](https://github.com/OpenSC/OpenSC/commit/1bb2547abca12f3ce22d48c3c171ea5e44ab4c4a)
e revertido em [7a090b99](https://github.com/OpenSC/OpenSC/commit/7a090b994e70a63a59825142dd6182332931bcdd).

Para resolver o problema, pode-se utilizar um dos três recursos:

* Caso não seja utilizado, remova o pacote opensc-pkcs11:
  
  ```bash
  sudo apt-get purge opensc-pkcs11
  ```

* Caso o OpenSC seja utilizado mas não precisa de integração com o p11-kit, desabilite seu módulo:

  ```bash
  sudo rm /usr/share/p11-kit/modules/opensc-pkcs11.module
  ```

* Caso o OpenSC não possa ser removido, compile uma nova versão:
  
  * Pode-se compilar diretamente dos fontes, contanto que se utilize uma versão com o patch [7a090b99](https://github.com/OpenSC/OpenSC/commit/7a090b994e70a63a59825142dd6182332931bcdd) aplicado.
  * Em vez de compilar diretamente dos fontes, recomendo [construir um novo pacote](https://help.ubuntu.com/community/UpdatingADeb)
    aplicando o patch [7a090b99](https://github.com/OpenSC/OpenSC/commit/7a090b994e70a63a59825142dd6182332931bcdd)

## 4. Recursos opcionais

> Esta seção é opcional. Pode ser completamente ignorada.

## 4.1. Configurar como serviço systemd

Para conectar via serviço (daemon) sem desbloqueio de token, é preciso que o PIN esteja salvo na URL do certificado.
Basta adicionar o campo `pin-value` ao final da URL no arquivo de configuração do OpenFortiVPN:

```text
user-cert = pkcs11:model=(…);manufacturer(…);serial=(…);token=(…);id=(…);object=(…);type=cert;pin-value=SEU_PIN_AQUI
```

Depois crie o .service do systemd em `/etc/systemd/system/openfortivpn.service`:

```text
[Unit]
Requires=pcscd.service
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/openfortivpn -c /CAMINHO_COMPLETO_PARA_O_CONFIG.cfg
```

## 4.2. Conexão automática ao inserir o Token

Para conectar a VPN após a inserção do Token, é preciso registrar o token via `udev` e criar um alias pra ele.

Crie o arquivo `/etc/udev/rules.d/99-eToken.rules`:

```text
# Procure o idVendor:idProduct de seu token via `lsusb`.
ACTION=="add", SUBSYSTEM=="usb" , ATTRS{idVendor}=="0529", ATTRS{idProduct}=="0600", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/etoken"

# PRODUCT é formado por idVendor/idProduct/idVersion sem o zero inicial.
ACTION=="remove", SUBSYSTEM=="usb", ENV{PRODUCT}=="529/600/*", TAG+="systemd"
```

Agora faça as seguintes alterações no openfortivpn.service:

* adicione a diretiva `BindsTo=dev-etoken.device` à seção `[Unit]`
* adicione a diretiva `WantedBy=dev-etoken.device` à seção `[Install]` (já vi funcionar sem esse ajuste, mas não consigui replicar)

## 5. Notas

### 5.1. Instalar apenas middleware do SafeNet

O driver do fabricante instala, além das libs necessárias, um daemon e uma porrada de utilitários para
gerenciamento de token. Se você não quiser instalar um caminhão de coisas inúteis, veja minha abordagem
em `install-vpn.sh`. Basta replicar em `/` a estrutura do diretório `pkg` deste repositório.

**Não confie nas minhas libs binárias .so que estão em `./pkg`**; faça você mesmo sua estrutura com as libs
do pacote que você baixou do Serpro.

### 5.2. Notas sobre a configuração de remoção do udev

A action `REMOVE` não é executada se forem utilizados atributos do udev como seletor.
Já atributo `ENV{PRODUCT}` é enviado pelo Kernel e não depende do udev.
Veja mais em <https://github.com/systemd/systemd/issues/7587>.

As variáveis ENV podem ser conferidas pelo comando `udevadm info /sys/path_do_device'

### 5.3. SYSTEMD_ALIAS

Devido ao `SYSTEMD_ALIAS`, um .device será registrado no formato `dev-etoken.device` (o path será normalizado com hífens).
Para ver informações sobre o dispositivo, execute:

```bash
systemctl status dev-etoken.device
```

### 5.4. OpenSSL

Para verificar as opções de compilação do openssl, execute:

```bash
openssl version -f
```

Para verificar quais as cifras habilitadas para terminado nível de segurança, execute:

```bash
openssl ciphers -s -v 'ALL:@SECLEVEL=2'
```

### 5.5. libp11 e libengine-pkcs11-openssl

 No Ubuntu 16.04, não bastasse a biblioteca `libengine-pkcs11-openssl=0.2.1-1` ter sido compilada sem suporte ao `libp11-kit-dev`,
a biblioteca `libp11` não consegue enumerar os certificados de um token pkcs11 (algum bug em `PKCS11_enumerate_certs`). Por isso,
é necessário compilar uma versão mais recente que a do respositório. Além disso, a partir da versão 0.4.0, a engine e a libp11
foram integradas no mesmo repositório.
