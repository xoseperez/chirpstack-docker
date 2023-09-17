#!/bin/sh

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------

COLOR_INFO="\e[32m" # green
COLOR_WARNING="\e[33m" # yellow
COLOR_ERROR="\e[31m" # red
COLOR_END="\e[0m"

# -----------------------------------------------------------------------------
# Identify concentrator
# -----------------------------------------------------------------------------

# Translate models
declare -A MODEL_TRANSLATE=(
    [rak7243]=rak_2245 [rak7243C]=rak_2245 [rak7244]=rak_2245 [rak7244C]=rak_2245 [rak7248]=rak_2287 [rak7248C]=rak_2287 [rak7271]=rak_2287 [rak7371]=rak_5146
    [rak831]=rak_2245 [rak833]=rak_2245 [rak2245]=rak_2245 [rak2247]=rak_2247 [rak2287]=rak_2287 [rak5146]=rak_5146 [rak5148]=rak_5148
    [ic880a]=imst_ic880a [wm1302]=seeed_wm1302 [sx1280zxxxxgw1]=semtech_sx1280z3dsfgw1
    [sx1301]=rak_2245 [sx1302]=rak_2287 [sx1303]=rak_5146 [sx1280]=semtech_sx1280z3dsfgw1
)
ORIGINAL_MODEL=$MODEL
MODEL=${MODEL_TRANSLATE[${MODEL,,}]:-$ORIGINAL_MODEL}
MODEL=${MODEL,,}

# Map models to design
declare -A MODEL_DESIGN=(
    [imst_ic880a]=sx1301 [kerlink_ifemtocell]=sx1301 [multitech_mtac_lora_h_868]=sx1301 [multitech_mtac_lora_h_915]=sx1301 
    [multitech_mtcap_lora_868]=sx1301 [multitech_mtcap_lora_915]=sx1301 [pi_supply_lora_gateway_hat]=sx1301 [rak_2245]=sx1301 
    [rak_2246]=sx1301 [rak_2247]=sx1301 [risinghf_rhf0m301]=sx1301 [sandbox_lorago_port]=sx1301 [wifx_lorix_one]=sx1301 
    [dragino_pg1302]=sx1302 [multitech_mtac_003e00]=sx1302 [multitech_mtac_003u00]=sx1302 [rak_2287]=sx1302 
    [rak_5146]=sx1302 [seeed_wm1302]=sx1302 [semtech_sx1302c490gw1]=sx1302 [semtech_sx1302c868gw1]=sx1302 
    [semtech_sx1302c915gw1]=sx1302 [semtech_sx1302css868gw1]=sx1302 [semtech_sx1302css915gw1]=sx1302 
    [semtech_sx1302css923gw1]=sx1302 [waveshare_sx1302_lorawan_gateway_hat]=sx1302 
    [multitech_mtac_lora_2g4]=2g4 [rak_5148]=2g4 [semtech_sx1280z3dsfgw1]=2g4 
)
DESIGN=${MODEL_DESIGN[$MODEL]}
if [[ "$DESIGN" == "" ]]; then
    echo -e "${COLOR_ERROR}ERROR: Unknown MODEL value ($MODEL). Valid values are: ${!MODEL_DESIGN[@]}${COLOR_END}"
    exit
fi

# -----------------------------------------------------------------------------
# Identify region and channels
# -----------------------------------------------------------------------------

# Get region
if [[ "$DESIGN" == "2g4" ]]; then
    REGION="ism2400"
else
    REGION=${REGION:-"eu868"}
fi
REGION=${REGION,,}

# Get channels
CHANNELS=${CHANNELS:-$REGION}
if [[ "$CHANNELS" == "us915" ]]; then CHANNELS="us915_0"; fi
if [[ "$CHANNELS" == "au915" ]]; then CHANNELS="au915_0"; fi
if [[ "$CHANNELS" == "cn470" ]]; then CHANNELS="cn470_0"; fi
CHANNELS=${CHANNELS,,}

# -----------------------------------------------------------------------------
# Gateway EUI (only sx1301)
# -----------------------------------------------------------------------------

if [[ "$DESIGN" == "sx1301" ]]; then

    # Source to check for EUI
    GATEWAY_EUI_SOURCE=${GATEWAY_EUI_SOURCE:-"manual"}

    # Get the Gateway EUI
    if [[ "$GATEWAY_EUI" == "" ]]; then

        if [[ `grep "$GATEWAY_EUI_SOURCE" /proc/net/dev` == "" ]]; then
            GATEWAY_EUI_SOURCE="eth0"
        fi
        if [[ `grep "$GATEWAY_EUI_SOURCE" /proc/net/dev` == "" ]]; then
            GATEWAY_EUI_SOURCE="wlan0"
        fi
        if [[ `grep "$GATEWAY_EUI_SOURCE" /proc/net/dev` == "" ]]; then
            GATEWAY_EUI_SOURCE="usb0"
        fi
        if [[ `grep "$GATEWAY_EUI_SOURCE" /proc/net/dev` == "" ]]; then
            GATEWAY_EUI_SOURCE="eth1"
        fi
        if [[ `grep "$GATEWAY_EUI_SOURCE" /proc/net/dev` == "" ]]; then
            # Last chance: get the most used NIC based on received bytes
            GATEWAY_EUI_SOURCE=$(cat /proc/net/dev | tail -n+3 | sort -k2 -nr | head -n1 | cut -d ":" -f1 | sed 's/ //g')
        fi
        if [[ `grep "$GATEWAY_EUI_SOURCE" /proc/net/dev` == "" ]]; then
            echo -e "${COLOR_ERROR}ERROR: No network interface found. Cannot set gateway EUI.${COLOR_END}"
        fi
        GATEWAY_EUI=$(ip link show $GATEWAY_EUI_SOURCE | awk '/ether/ {print $2}' | awk -F\: '{print $1$2$3"FFFE"$4$5$6}')

    fi
    GATEWAY_EUI=${GATEWAY_EUI^^}

    # Check we have an EUI
    if [[ -z ${GATEWAY_EUI} ]] ; then
        echo -e "${COLOR_ERROR}ERROR: GATEWAY_EUI not set.${COLOR_END}"
        exit
    fi

fi

# -----------------------------------------------------------------------------
# Identify interface
# -----------------------------------------------------------------------------

# Models with USB interface
MODELS_WITH_USB="RAK7271 RAK7371 RAK5148 SX1280ZXXXXGW1"
if [[ $MODELS_WITH_USB =~ (^|[[:space:]])${ORIGINAL_MODEL^^}($|[[:space:]]) ]]; then
    INTERFACE="${INTERFACE:-"USB"}"
else
    INTERFACE=${INTERFACE:-"SPI"}
fi

# -----------------------------------------------------------------------------
# GPIO configuration
# -----------------------------------------------------------------------------

# If interface is USB disable RESET_GPIO, otherwise default to 17
if [[ "$INTERFACE" == "SPI" ]]; then
    RESET_GPIO=${RESET_GPIO:-17}
else
    RESET_GPIO=${RESET_GPIO:-0}
fi

# The RAK833-SPI/USB has a SPDT to select USB/SPI interfaces
# If used with RAK2247 or RAK2287 hats this is wired to GPIO20
if [[ "${ORIGINAL_MODEL^^}" == "RAK833" ]]; then
    if [[ "$INTERFACE" == "SPI" ]]; then
        POWER_EN_GPIO=${POWER_EN_GPIO:-20}
        POWER_EN_LOGIC=${POWER_EN_LOGIC:-0}
    fi
fi

# Otherwise the default is no power enable pin
POWER_EN_GPIO=${POWER_EN_GPIO:-0}
POWER_EN_LOGIC=${POWER_EN_LOGIC:-1}

# -----------------------------------------------------------------------------
# GPS Configuration
# -----------------------------------------------------------------------------

# Models with GPS
MODELS_WITH_GPS="RAK7243 RAK7243C RAK7244 RAK7244C RAK7246G RAK7248 RAK7248C RAK831 RAK2245"
if [[ $MODELS_WITH_GPS =~ (^|[[:space:]])${ORIGINAL_MODEL^^}($|[[:space:]]) ]]; then
    HAS_GPS=${HAS_GPS:-1}
fi
HAS_GPS=${HAS_GPS:-0}

# -----------------------------------------------------------------------------
# Debug
# -----------------------------------------------------------------------------

echo -e "${COLOR_INFO}------------------------------------------------------------------${COLOR_END}"
 
if [[ "$MODEL" != "$ORIGINAL_MODEL" ]]; then
echo -e "${COLOR_INFO}Model:          $MODEL ($ORIGINAL_MODEL)${COLOR_END}"
else
echo -e "${COLOR_INFO}Model:          $MODEL${COLOR_END}"
fi
echo -e "${COLOR_INFO}Design:         ${DESIGN}${COLOR_END}"
echo -e "${COLOR_INFO}Interface:      $INTERFACE${COLOR_END}"
if [[ "$INTERFACE" == "SPI" ]]; then
echo -e "${COLOR_INFO}Reset GPIO:     $RESET_GPIO${COLOR_END}"
echo -e "${COLOR_INFO}Enable GPIO:    $POWER_EN_GPIO${COLOR_END}"
fi
if [[ "$DESIGN" == "sx1301" ]]; then
echo -e "${COLOR_INFO}Gateway EUI:    $GATEWAY_EUI${COLOR_END}"
fi
echo -e "${COLOR_INFO}Region:         $REGION${COLOR_END}"
echo -e "${COLOR_INFO}Channels:       $CHANNELS${COLOR_END}"
echo -e "${COLOR_INFO}Has GPS:        $HAS_GPS${COLOR_END}"

echo -e "${COLOR_INFO}------------------------------------------------------------------${COLOR_END}"

# -----------------------------------------------------------------------------
# Build configuration
# -----------------------------------------------------------------------------

# Copy the right files to work folder
cp ./artifacts/configs/chirpstack-concentratord-${DESIGN}/concentratord.toml  ./concentratord.toml
cp ./artifacts/configs/chirpstack-concentratord-${DESIGN}/region_${REGION}.toml ./region.toml
cp ./artifacts/configs/chirpstack-concentratord-${DESIGN}/channels_${CHANNELS}.toml ./channels.toml

# Calculate model flags
MODEL_FLAGS=""
if [[ "$INTERFACE" == "USB" ]]; then MODEL_FLAGS="$MODEL_FLAGS USB"; fi
if [[ $HAS_GPS -eq 1 ]]; then MODEL_FLAGS="$MODEL_FLAGS GNSS"; fi
MODEL_FLAGS=$( echo ${MODEL_FLAGS##*( )} | sed 's/^/["/' | sed 's/$/"]/' | sed 's/ /","/' )

# modify the settings based on environment variables
sed "s/model=\".*\"/model=\"${MODEL}\"/" -i concentratord.toml 
sed "s/region=\".*\"/region=\"${REGION^^}\"/" -i concentratord.toml 
sed "s/gateway_id=\".*\"/gateway_id=\"${GATEWAY_EUI^^}\"/" -i concentratord.toml 
sed "s/log_level=\".*\"/log_level=\"${DEBUG:-"INFO"}\"/" -i concentratord.toml 
sed "s/log_to_syslog=.*/log_to_syslog=false/" -i concentratord.toml 
if [ "$SOCKET_PREFIX" != "" ]; then
    sed "s/_bind=\"ipc:\/\/\/tmp\/concentratord_/_bind=\"ipc:\/\/\/tmp\/concentratord_${SOCKET_PREFIX}_/" -i concentratord.toml 
fi

if [[ "$DESIGN" == "sx1301" ]]; then
    sed "s/model_flags=.*/model_flags=${MODEL_FLAGS}/" -i concentratord.toml 
    sed "s/reset_pin=.*/reset_pin=${RESET_GPIO^^}/" -i concentratord.toml 
fi

if [[ "$DESIGN" == "sx1302" ]]; then
    sed "s/model_flags=.*/model_flags=${MODEL_FLAGS}/" -i concentratord.toml 
    if [[ $RESET_GPIO -ne 0 ]]; then echo -e "\nsx1302_reset_pin=${RESET_GPIO^^}" >> concentratord.toml ; fi
    if [[ $POWER_EN_GPIO -ne 0 ]]; then echo -e "\nsx1302_power_en_pin=${POWER_EN_GPIO^^}" >> concentratord.toml ; fi
fi


# -----------------------------------------------------------------------------
# Get binary
# -----------------------------------------------------------------------------

tar -xf ./artifacts/binaries/chirpstack-concentratord-${DESIGN}*
mv chirpstack-concentratord-${DESIGN} chirpstack-concentratord

# -----------------------------------------------------------------------------
# Start concentratord
# -----------------------------------------------------------------------------
./chirpstack-concentratord -c ./concentratord.toml -c ./region.toml -c ./channels.toml
