# tcc-streaming
Repositório com os códigos usados para meu TCC na criação de um mini projeto de streaming
# Requisitos
- Uma máquina para codificar o conteúdo (nossa fonte)
- Uma máquina (ou servidor) para receber o conteúdo codificado e empacotá-lo para distribuição
- Software de servidor web
- Software de Manipulação de Vídeo
# Passo a Passo
## Preparando o servidor web parte 1: instalando o NGINX
Vamos começar esse manual a partir do ponto em que providenciamos as máquinas necessárias para realizar o trabalho. Para conseguir essas máquinas, tanto as codificações quanto os servidores de distribuição, é possível procurar por um provedor à sua escolha na internet e que atenda às suas necessidades/realidades.

Uma vez com o servidor em mãos, é necessário acessar o terminal e logar com credenciais de administrador, para que possamos começar a fazer as instalações necessárias. O primeiro software que instalaremos será o NGINX.

NGINX ;e um software open source voltado para servidores web. Ele será resposnável por pegar o vídeo que codificaremos em nossa máquina e empacotá-lo de forma que seja possível trafegar na web até os usuários finais

Contudo, ele não vem pronto nos pacotes oficiais. Para que possamos enviar nossos vídeos para o servidor web, precisamos usar o protocolo de tráfego de conteídp pela internet RTMP, que a versão padrão do NGINX não suporta. Felizmente existe um módulo bem suportado que acrescenta a funcionalidade para o pacote

O módulo usado foi o: https://github.com/sergey-dryabzhinsky/nginx-rtmp-module

1. Começaremos fazendo a clonagem do módulo RTMP para o nosso servidor, por meio do comando `git clone`
```git
git clone https://github.com/sergey-dryabzhinsky/nginx-rtmp-module.git
```
2. Em seguida instalamos algumas dependências do NGINX, em preparação para a compilação da versão com o módulo RTMP
```git
sudo apt-get install build-essential libpcre3 libpcre3-dev libssl-dev
```
3. Agora que temos todas as dependências instaladas, podemos baixar o pacote principal do nginx. Na criação desse manual, a versão mais atual é a 1.26.2 e pode ser encontrada nesse link: https://nginx.org/en/download.html
```git
wget https://nginx.org/download/nginx-1.26.2.tar.gz
tar -xf nginx-1.26.2.tar.gz
cd nginx-1.26.2
```
Agora já temos todos os arquivos necessários para começar a compilação da nossa versão expandida do nginx
4. Dentro da pasta extraída do nginx-1.26.2, vamos compilar a nossa própria versão do NGINX com o módulo RTMP previamente baixado
```git
./configure --with-http_ssl_module --add-module=caminho/para/módulo/rtmp
make -j 1
sudo make install
```
*  OBS: Idealmente o módulo RTMP estará na pasta anterior, mas independente de onde esteja, é necessário fazer o apontamento correto ao acrescentá-lo usando o comando "add-module"
5. Pronto! Agora já temos o nginx instalado com o módulo RTMP pronto. Os próximos passos servirão para configurar o NGINX corretamente
## Preparando o servidor web parte 2: configurando o NGINX
O arquivo conf do nginx é essencial para que consigamos entregar qualquer conteúdo na web. Ele dita como o NGINX deve se comportar dependendo do pedido de recebimento/envio que chega até o nosso servidor
Normalmente o arquivo nginx.conf fica localizado no caminho /usr/local/nginx/conf/nginx.conf or /etc/nginx/nginx.conf
Disponibilizei nesse mesmo repositório o arquivo que eu usei para que minha página funcionasse. Para esse manual, focarei apenas em explicar alguns dos principais pontos:
1. Criaremos uma "app" RTMP na configuração do RTMP:
```conf
rtmp{
  server{
    listen 1935; #Essa linha indica que o módulo leia por protocolo rtmp na porta padrão 1935
    chunk_size 4000;

  application NOME { #aqui podemos dar um nome específico para o conteúdo que vamos exibir, dependendo de como for consumido esse valor pode ser relevante ou não
    live on;
    hls on; #HLS é um protocolo para entregar vídeo na internet em pedações de tamanho fixo
    hls_path /mnt/hls/;
    hls_fragment 3; # Essa linha e a de baixo podem ser modificadas dependendo das necessidades e/ou vontades de projeto
    hls_playlist_length 60;
    deny play all;
}
}
}
```
2. Criaremos agora uma app de servidor HTTP, para entrega dos pacotes HLS e para servir nosso website
```conf
server {
    listen 8080;
    server_name nome.do.servidor.com; #como temos uma página web para ser servida, acrescentamos a sua URL aqui

    location /hls {
        add_header Cache-Control no-cache;

        # CORS são políticas usadas por navegadores web para saber quais pontos de origem podem carregar conteúdo
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length';

        # Mais configurações de CORS
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain charset=UTF-8';
            add_header 'Content-Length' 0;
            return 204;
        }

        types {
            application/vnd.apple.mpegurl m3u8;
            video/mp2t ts;
        }

        root /mnt/;
}
}
```
## Iniciando e operando o NGINX
Por padrão o ningx é instalado no local /usr/local/nginx/sbin/nginx, mas isso pode ser diferente caso queira
Seguem alguns comandos interessantes para saber do NGINX
*Iniciando o NGINX no plano de fundo
```
/usr/local/nginx/sbin/nginx
```
*Iniciando o NGINX por cima do shell
```
/usr/local/nginx/sbin/nginx -g 'daemon off;'
```
*Teste de arquivo de configuração (esse é um bom comando pq indica diretamente se tem algum erro no nginx.conf)
```
/usr/local/nginx/sbin/nginx -t
```
*Interrompendo o nignx
```
/usr/local/nginx/sbin/nginx -s stop
```

E com isso, temos tudo que é necessário para começar a enviar conteúdo para esse servidor web

Para fazer isso, na nossa fonte, precisamos nos atentar para colocar como destino:
```
rtmp://nome.do.servidor.com/NOME/titulo
```
Onde `nome.do.servidor.com` é o nome que configuramos na app http do conf, `NOME` é o nome da aplicação RTMP que também configuramos no conf e `titulo` é o nome que quisermos dar ao nosso conteúdo. Na pasta HLS dentro do nginx os pacotes serão nomeados a partir do titulo
