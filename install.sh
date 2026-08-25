#!/bin/bash
#
# METATRON-BEAST Installation Script
# ===================================
# Optimized for: Ryzen 9 5900X, RTX 5070 Ti (16GB VRAM), 32GB RAM
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           METATRON-BEAST INSTALLER                           ║"
echo "║   Aggressive Network Security Audit Suite                    ║"
echo "║   Hardware: Ryzen 9 5900X | RTX 5070 Ti | 32GB RAM           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check root for package installation
if [[ $EUID -ne 0 ]]; then
   echo -e "${YELLOW}[!] Some features require root. Run with sudo for full install.${NC}"
fi

# =============================================================================
# STEP 1: Install Dependencies
# =============================================================================

echo -e "\n${GREEN}[1/5] Installing dependencies...${NC}"

# Detect package manager
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt-get"
    sudo apt-get update
    sudo apt-get install -y \
        nmap \
        nikto \
        whatweb \
        gobuster \
        hydra \
        enum4linux \
        smbclient \
        snmp \
        aircrack-ng \
        reaver \
        hcxdumptool \
        hcxtools \
        arp-scan \
        python3-pip \
        python3-venv \
        wireless-tools \
        net-tools \
        curl \
        git
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    sudo pacman -Syu --noconfirm \
        nmap nikto whatweb gobuster hydra \
        enum4linux smbclient net-snmp \
        aircrack-ng reaver hcxdumptool hcxtools \
        arp-scan python-pip wireless_tools net-tools curl git
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    sudo dnf install -y \
        nmap nikto whatweb hydra \
        samba-client net-snmp-utils \
        aircrack-ng arp-scan python3-pip \
        wireless-tools net-tools curl git
else
    echo -e "${RED}[!] Unknown package manager. Install dependencies manually.${NC}"
fi

# Python dependencies
pip3 install --user paho-mqtt requests

# =============================================================================
# STEP 2: Install Ollama
# =============================================================================

echo -e "\n${GREEN}[2/5] Installing/Checking Ollama...${NC}"

if ! command -v ollama &> /dev/null; then
    echo "[*] Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "[+] Ollama already installed"
fi

# Start Ollama service
sudo systemctl enable ollama 2>/dev/null || true
sudo systemctl start ollama 2>/dev/null || true

# Wait for Ollama to be ready
sleep 3

# =============================================================================
# STEP 3: Model Selection and Download
# =============================================================================

echo -e "\n${GREEN}[3/5] Model Selection...${NC}"

echo ""
echo "Select base model for your 16GB VRAM:"
echo ""
echo "  1) qwen2.5:14b-instruct-q4_K_M  (~9GB VRAM, fastest)"
echo "  2) qwen2.5:32b-instruct-q3_K_M  (~14GB VRAM, best quality/speed)"
echo "  3) qwen2.5:32b-instruct-q4_K_M  (~18GB VRAM, highest quality, uses RAM offload)"
echo ""
read -p "Choice [1-3, default=2]: " model_choice

case $model_choice in
    1)
        BASE_MODEL="qwen2.5:14b-instruct-q4_K_M"
        ;;
    3)
        BASE_MODEL="qwen2.5:32b-instruct-q4_K_M"
        ;;
    *)
        BASE_MODEL="qwen2.5:32b-instruct-q3_K_M"
        ;;
esac

echo "[*] Downloading ${BASE_MODEL}..."
ollama pull ${BASE_MODEL}

# =============================================================================
# STEP 4: Create Custom Model
# =============================================================================

echo -e "\n${GREEN}[4/5] Creating METATRON-BEAST model...${NC}"

# Update Modelfile with selected base
sed -i "s|^FROM .*|FROM ${BASE_MODEL}|" Modelfile

# Create the custom model
ollama create metatron-beast -f Modelfile

echo "[+] Model metatron-beast created successfully!"

# =============================================================================
# STEP 5: Verify Installation
# =============================================================================

echo -e "\n${GREEN}[5/5] Verifying installation...${NC}"

echo ""
echo "Checking tools:"

tools=("nmap" "nikto" "whatweb" "gobuster" "hydra" "aircrack-ng" "arp-scan" "ollama")
for tool in "${tools[@]}"; do
    if command -v $tool &> /dev/null; then
        echo -e "  [${GREEN}✓${NC}] $tool"
    else
        echo -e "  [${RED}✗${NC}] $tool (missing)"
    fi
done

# =============================================================================
# COMPLETE
# =============================================================================

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              INSTALLATION COMPLETE!                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Usage:"
echo ""
echo "  1. Test the model:"
echo "     ollama run metatron-beast"
echo ""
echo "  2. Run network scan:"
echo "     sudo python3 scanner_aggressive.py 192.168.1.0/24 -p AGGRESSIVE"
echo ""
echo "  3. Run WiFi audit (requires monitor-mode adapter):"
echo "     sudo python3 wifi_attacks.py -i wlan0"
echo ""
echo "  4. Run IoT scan:"
echo "     sudo python3 iot_scanner.py 192.168.1.0/24"
echo ""
echo -e "${YELLOW}[!] Remember: Only scan networks you own or have permission to test!${NC}"
echo ""
