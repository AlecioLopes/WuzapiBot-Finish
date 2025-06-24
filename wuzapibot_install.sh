#!/data/data/com.termux/files/usr/bin/bash

# Cores para personalização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Banner WUZAPIBOT
echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║  ██╗    ██╗██╗   ██╗███████╗ █████╗ ██████╗ ██╗██████╗  ██████╗ ████████╗ ║"
echo "║  ██║    ██║██║   ██║╚══███╔╝██╔══██╗██╔══██╗██║██╔══██╗██╔═══██╗╚══██╔══╝ ║"
echo "║  ██║ █╗ ██║██║   ██║  ███╔╝ ███████║██████╔╝██║██████╔╝██║   ██║   ██║    ║"
echo "║  ██║███╗██║██║   ██║ ███╔╝  ██╔══██║██╔═══╝ ██║██╔══██╗██║   ██║   ██║    ║"
echo "║  ╚███╔███╔╝╚██████╔╝███████╗██║  ██║██║     ██║██████╔╝╚██████╔╝   ██║    ║"
echo "║   ╚══╝╚══╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═════╝  ╚═════╝    ╚═╝    ║"
echo "║                                                              ║"
echo "║              ${WHITE}Instalação Automatizada do WuzAPI${CYAN}              ║"
echo "║                     ${YELLOW}Termux WhatsApp Bot${CYAN}                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Script para instalar o WuzAPI no Termux (instalação padrão com SQLite, criação manual do usuário, correção de diretório temporário)

# Variáveis configuráveis
ADMIN_TOKEN="3129"         # Token de administrador
USER_TOKEN="7774"          # Token do usuário para login e API
PORT=8080                  # Porta do WuzAPI
WEBHOOK_URL="http://localhost:3129/tasker"  # Webhook para eventos
TMP_DIR="$HOME/wuzapi/tmp" # Diretório temporário para mídias

# Função para verificar erros
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}${BOLD}Erro: $1${NC}"
        exit 1
    fi
}

# 1. Validar tokens
echo -e "${MAGENTA}${BOLD}[VALIDAÇÃO] Verificando configurações...${NC}"
if [ -z "$ADMIN_TOKEN" ]; then
    echo -e "${RED}${BOLD}Erro: O ADMIN_TOKEN não pode ser vazio.${NC}"
    exit 1
fi
if [ -z "$USER_TOKEN" ]; then
    echo -e "${RED}${BOLD}Erro: O USER_TOKEN não pode ser vazio.${NC}"
    exit 1
fi
if [ -z "$WEBHOOK_URL" ]; then
    echo -e "${RED}${BOLD}Erro: O WEBHOOK_URL não pode ser vazio.${NC}"
    exit 1
fi

# 2. Limpar cache do apt
echo -e "${YELLOW}${BOLD}[LIMPEZA] Limpando cache do apt...${NC}"
apt-get clean
apt-get autoclean
check_error "Falha ao limpar cache do apt"

# 3. Atualizar pacotes do Termux com confirmação automática
echo -e "${BLUE}${BOLD}[ATUALIZAÇÃO] Atualizando pacotes do Termux...${NC}"
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y --option Dpkg::Options::="--force-confnew"
check_error "Falha ao atualizar pacotes do Termux"

# 4. Instalar dependências com confirmação automática
echo -e "${GREEN}${BOLD}[INSTALAÇÃO] Instalando dependências (Go, Git, SQLite, Nano, net-tools)...${NC}"
DEBIAN_FRONTEND=noninteractive apt-get install -y golang git sqlite nano net-tools
check_error "Falha ao instalar dependências"

# 5. Verificar instalação do Go
echo -e "${CYAN}${BOLD}[VERIFICAÇÃO] Verificando versão do Go...${NC}"
go version
check_error "Go não está instalado corretamente"

# 6. Configurar Git para evitar autenticação
echo -e "${MAGENTA}${BOLD}[CONFIGURAÇÃO] Configurando Git para clonagem anônima...${NC}"
git config --global credential.helper ''
check_error "Falha ao configurar Git"

# 7. Clonar o repositório do WuzAPI
echo -e "${BLUE}${BOLD}[DOWNLOAD] Clonando o repositório do WuzAPI...${NC}"
if [ -d "wuzapi" ]; then
    echo -e "${YELLOW}Diretório wuzapi já existe. Removendo e clonando novamente...${NC}"
    rm -rf wuzapi
fi
git clone https://github.com/asternic/wuzapi.git
cd wuzapi
check_error "Falha ao clonar ou acessar o repositório"

# 8. Criar diretório temporário
echo -e "${GREEN}${BOLD}[CRIAÇÃO] Criando diretório temporário em $TMP_DIR...${NC}"
mkdir -p "$TMP_DIR"
chmod 700 "$TMP_DIR"
check_error "Falha ao criar diretório temporário"

# 9. Atualizar dependências do Go
echo -e "${CYAN}${BOLD}[DEPENDÊNCIAS] Atualizando dependências do Whatsmeow...${NC}"
go get -u go.mau.fi/whatsmeow@latest
go mod tidy
check_error "Falha ao atualizar dependências"

# 10. Criar arquivo .env com configuração padrão (SQLite)
echo -e "${MAGENTA}${BOLD}[CONFIGURAÇÃO] Criando arquivo de configuração .env...${NC}"
cat << EOF > .env
WUZAPI_ADMIN_TOKEN=$ADMIN_TOKEN
TZ=America/Sao_Paulo
SESSION_DEVICE_NAME=WuzAPI
TMPDIR=$TMP_DIR
EOF
check_error "Falha ao criar arquivo .env"

# 11. Compilar o WuzAPI
echo -e "${YELLOW}${BOLD}[COMPILAÇÃO] Compilando o WuzAPI...${NC}"
go build .
check_error "Falha ao compilar o WuzAPI"

# 12. Verificar e liberar a porta
echo -e "${BLUE}${BOLD}[REDE] Verificando a porta $PORT...${NC}"
for attempt in {1..5}; do
    if lsof -i :$PORT >/dev/null 2>&1 || fuser $PORT/tcp >/dev/null 2>&1; then
        echo -e "${YELLOW}[!] Porta $PORT em uso. Tentativa $attempt de liberar...${NC}"
        echo -e "${CYAN}[*] Processos detectados:${NC}"
        lsof -i :$PORT 2>/dev/null || true
        fuser $PORT/tcp 2>/dev/null || true
        kill -9 $(lsof -t -i:$PORT) 2>/dev/null || true
        fuser -k -n tcp $PORT 2>/dev/null || true
        sleep 1
    else
        echo -e "${GREEN}[+] Porta $PORT está livre.${NC}"
        break
    fi
    if [ $attempt -eq 5 ]; then
        echo -e "${RED}${BOLD}[ERRO] Falha ao liberar porta $PORT após 5 tentativas.${NC}"
        echo -e "${YELLOW}Verifique manualmente com: lsof -i :$PORT ou fuser $PORT/tcp${NC}"
        exit 1
    fi
done

# 13. Instruções finais
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║            🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO! 🎉           ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}${BOLD}📋 CONFIGURAÇÕES:${NC}"
echo -e "${WHITE}Token de admin: ${GREEN}$ADMIN_TOKEN${NC}"
echo -e "${WHITE}Token de usuário: ${GREEN}$USER_TOKEN${NC}"
echo -e "${WHITE}Porta: ${GREEN}$PORT${NC}"
echo -e "${WHITE}Webhook: ${GREEN}$WEBHOOK_URL${NC}"
echo -e "${WHITE}Diretório temporário: ${GREEN}$TMP_DIR${NC}"

echo -e "${MAGENTA}${BOLD}⚙️ ARQUIVO .ENV CONFIGURADO COM:${NC}"
echo -e "${YELLOW}  WUZAPI_ADMIN_TOKEN=$ADMIN_TOKEN${NC}"
echo -e "${YELLOW}  TZ=America/Sao_Paulo${NC}"
echo -e "${YELLOW}  SESSION_DEVICE_NAME=WuzAPI${NC}"
echo -e "${YELLOW}  TMPDIR=$TMP_DIR${NC}"
echo ""

echo -e "${BLUE}${BOLD}🚀 PARA INICIAR O WUZAPI:${NC}"
echo -e "${WHITE}  cd ~/wuzapi && ./wuzapi -logtype=console -color=true -port=$PORT${NC}"
echo -e "${CYAN}Acesse ${GREEN}http://localhost:$PORT/login?token=$USER_TOKEN${CYAN} para escanear o QR code.${NC}"
echo ""

echo -e "${MAGENTA}${BOLD}👤 CRIAR USUÁRIO MANUALMENTE:${NC}"
echo -e "${WHITE}Execute o seguinte comando após iniciar o WuzAPI:${NC}"
echo -e "${YELLOW}  curl -X POST http://localhost:$PORT/admin/users \\${NC}"
echo -e "${YELLOW}  -H \"Authorization: $ADMIN_TOKEN\" \\${NC}"
echo -e "${YELLOW}  -H \"Content-Type: application/json\" \\${NC}"
echo -e "${YELLOW}  -d '{\"name\":\"test_user\",\"token\":\"$USER_TOKEN\",\"events\":\"All\",\"webhook\":\"$WEBHOOK_URL\"}'${NC}"
echo ""

echo -e "${CYAN}${BOLD}📱 TERMUX:TASKER:${NC}"
echo -e "${WHITE}Certifique-se de que o Termux:Tasker está configurado para receber POSTs na porta 3129.${NC}"
echo ""

echo -e "${RED}${BOLD}⚠️ AVISO IMPORTANTE:${NC}"
echo -e "${YELLOW}O uso do WuzAPI pode violar os Termos de Serviço do WhatsApp. Use por sua conta e risco.${NC}"
echo ""

# 14. Iniciar o WuzAPI automaticamente
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║               🚀 INICIANDO WUZAPIBOT 🚀                      ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}${BOLD}🔥 Iniciando o WuzAPI automaticamente...${NC}"
echo -e "${WHITE}Acesse ${GREEN}http://localhost:$PORT/login?token=$USER_TOKEN${WHITE} para escanear o QR code.${NC}"
echo ""

cd ~/wuzapi && ./wuzapi -logtype=console -color=true -port=$PORT
