#!/bin/bash

# Script para instalar e configurar o screenfetch com informações personalizadas
# Empresa: itConnect Tecnologia da Informação Ltda.

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    echo "Este script precisa ser executado como root. Use sudo."
    exit 1
fi

# Função para detectar a distribuição e instalar o screenfetch
install_screenfetch() {
    echo "Detectando distribuição e instalando screenfetch..."
    if [ -f /etc/debian_version ]; then
        apt-get update
        apt-get install -y screenfetch
    elif [ -f /etc/redhat-release ]; then
        yum install -y epel-release
        yum install -y screenfetch
    elif [ -f /etc/arch-release ]; then
        pacman -Sy screenfetch
    else
        echo "Distribuição não suportada. Instale o screenfetch manualmente."
        exit 1
    fi
}

# Função para criar script personalizado de inicialização
create_custom_script() {
    echo "Criando script personalizado para exibir informações do sistema..."
    cat > /usr/local/bin/custom_screenfetch.sh << 'EOF'
#!/bin/bash

# Script personalizado para exibir informações do sistema
# Empresa: itConnect Tecnologia da Informação Ltda.

# Obtém as informações solicitadas
HOSTNAME=$(hostname)
IP_ADDRESS=$(ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
KERNEL_VERSION=$(uname -r)
OS_VERSION=$(cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f 2)

# Exibe o logotipo da empresa e informações com screenfetch
echo "------------------------------------------------------------"
echo "  itConnect Tecnologia da Informação Ltda. - Soluções em TI  "
echo "------------------------------------------------------------"
echo "Endereço: Rua Domingos André Zanini, 277 Empresarial Terrafirme, Loja 17"
echo "          Campinas, São José - SC, 88117-200"
echo "Telefone: (48) 3121-0000"
echo "------------------------------------------------------------"
screenfetch
echo "------------------------------------------------------------"
echo "Nome do Servidor: $HOSTNAME"
echo "Endereço IP: $IP_ADDRESS"
echo "Versão do Kernel: $KERNEL_VERSION"
echo "Versão do Sistema: $OS_VERSION"
echo "------------------------------------------------------------"
EOF

    # Torna o script executável
    chmod +x /usr/local/bin/custom_screenfetch.sh
}

# Função para configurar a execução na inicialização para todos os usuários
setup_autostart() {
    echo "Configurando execução na inicialização para todos os usuários..."
    # Adiciona ao /etc/profile para executar no login de qualquer usuário
    if ! grep -q "custom_screenfetch.sh" /etc/profile; then
        echo "[ -f /usr/local/bin/custom_screenfetch.sh ] && /usr/local/bin/custom_screenfetch.sh" >> /etc/profile
    fi
}

# Executa as funções
install_screenfetch
create_custom_script
setup_autostart

echo "Instalação e configuração concluídas com sucesso!"
echo "As informações do sistema serão exibidas no login de qualquer usuário."