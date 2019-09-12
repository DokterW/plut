#!/bin/bash
# plut v0.11
# Made by Dr. Waldijk
# PEPPOL Look-Up Tool.
# Read the README.md for more info.
# By running this script you agree to the license terms.
# Config ----------------------------------------------------------------------------
PLUTNAM="plut"
PLUTVER="0.11"
PLUTOPT=$1
PLUTSRC="$2 $3 $4 $5 $6 $7 $8 $9"
PLUTSRC=$(echo $PLUTSRC | sed -r 's/ /%20/g')
# Dependencies ----------------------------------------------------------------------
if [ ! -e /usr/bin/curl ] && [ ! -e /usr/bin/jq ]; then
    #FNUOSD=$(cat /etc/system-release | grep -oE '^[A-Z][a-z]+\s' | sed '1s/\s//')
    FNUOSD=$(cat /etc/os-release | grep -oE '^ID=' | sed 's/ID=//')
    if [[ "$FNUOSD" = "fedora" ]]; then
        sudo dnf -y install curl jq fmt
    elif [[ "$FNUOSD" = "ubuntu" ]]; then
        sudo apt install curl jq
    else
        echo "You need to install curl and jq."
        exit
    fi
elif [ ! -e /usr/bin/curl ]; then
    FNUOSD=$(cat /etc/system-release | grep -oE '^[A-Z][a-z]+\s' | sed '1s/\s//')
    if [ "$FNUOSD" = "Fedora" ]; then
        sudo dnf -y install curl
    elif [[ "$FNUOSD" = "ubuntu" ]]; then
        sudo apt install curl
    else
        echo "You need to install curl."
        exit
    fi
elif [ ! -e /usr/bin/jq ]; then
    FNUOSD=$(cat /etc/system-release | grep -oE '^[A-Z][a-z]+\s' | sed '1s/\s//')
    if [ "$FNUOSD" = "Fedora" ]; then
        sudo dnf -y install jq
    elif [[ "$FNUOSD" = "ubuntu" ]]; then
        sudo apt install jq
    else
        echo "You need to install jq."
        exit
    fi
fi
# Functions -------------------------------------------------------------------------
#doctyp () {
#    x
#}
# -----------------------------------------------------------------------------------
if [[ "$PLUTOPT" = "search" ]] || [[ "$PLUTOPT" = "s" ]] && [[ -n $PLUTSRC ]]; then
    # https://peppol.helger.com/public/locale-en_US/menuitem-tools-rest-api
    PLUTCHK=$(echo $PLUTSRC | grep -E '^[0-9]{4}:.*$')
    if [[ -n $PLUTCHK ]]; then
        PLUTAPI=$(curl -s "https://peppol.helger.com/api/smpquery/digitprod/iso6523-actorid-upis::$PLUTSRC?businessCard=true")
        PLUTDAP=$PLUTAPI
        PLUTCHK=$(echo $PLUTAPI | grep -o 'HTTP Status 404' | head -n 1)
        if [[ -z $PLUTCHK ]] && [[ -n $PLUTAPI ]]; then
            PLUTDOC=$(echo $PLUTDAP | jq -r '.urls[0].documentTypeID')
            if [[ "$PLUTDOC" != "null" ]]; then
                PLUTDOC=$(echo $PLUTDOC | sed -r "s/#/%23/g")
                PLUTDAP=$(curl -s "https://peppol.helger.com/api/smpquery/digitprod/iso6523-actorid-upis::$PLUTSRC/$PLUTDOC")
            fi
            # echo "[PEPPOL @ Helger]"
            #    PLUTCHK=$(echo "$PLUTSRC" | cut -d : -f 1)
            #    if [[ "$PLUTCHK" = "0192" ]] || [[ "$PLUTCHK" = "9908" ]]; then
            #        PLUTNOR=$(echo "$PLUTSRC" | cut -d : -f 2)
            #        PLUTELM=$(curl -s "https://hotell.difi.no/api/json/difi/elma/participants?query=$PLUTNOR")
            #        echo "$PLUTELM" | jq -r ".entries[0].name" | sed -r 's/(.*)/   Company: \1/'
            #    else
            #        PLUTDIR=$(curl -s "https://directory.peppol.eu/search/1.0/json?participant=iso6523-actorid-upis::$PLUTSRC")
            #        echo "$PLUTDIR" | jq -r '.matches[].entities[].name[].name' | sed -r 's/(.*)/   Company: \1/'
            #    fi
            PLUTCHK=$(echo $PLUTAPI | jq -r '.businessCard.entity[].name[].name' | grep -o 'null' | head -n 1)
            if [[ "$PLUTCHK" != "null" ]]; then
                echo $PLUTAPI | jq -r '.businessCard.entity[].name[].name' | sed -r 's/(.*)/   Company: \1/'
                echo $PLUTAPI | jq -r '.businessCard.entity[].countrycode' | sed -r 's/(.*)/   Country: \1/'
            fi
            echo $PLUTAPI | jq -r '.participantID' | sed -r 's/iso6523-actorid-upis::(.*)/       eID: \1/'
            # PLUTCNT=0
            # while :; do
            #    PLUTCHK=$(echo $PLUTDAP | jq -r ".urls[$PLUTCNT].documentTypeID" | grep 'Invoice')
            #    PLUTCNT=$(expr $PLUTCNT + 1)
            #    if [[ -n $PLUTCHK ]]; then
            #        #echo ""
            #        break
            #    fi
            # done
            if [[ "$PLUTDOC" != "null" ]]; then
                echo $PLUTDAP | jq -r '.serviceinfo.processes[].endpoints[0].serviceDescription' | sed -r 's/(.*)/        AP: \1/'
                echo $PLUTDAP | jq -r '.serviceinfo.processes[].endpoints[0].technicalContactUrl' | sed -r 's/(.*)/AP Contact: \1/'
                echo ""
                PLUTCNT=0
                echo " Documents:"
                while :; do
                    PLUTCHK=$(echo $PLUTAPI | jq -r ".urls[$PLUTCNT].documentTypeID")
                    if [[ "$PLUTCHK" = "null" ]]; then
                        break
                    fi
                    if [[ "$PLUTCHK" != "null" ]] && [[ "$PLUTCNT" != "0" ]]; then
                        echo ""
                    fi
                    echo $PLUTAPI | jq -r ".urls[$PLUTCNT].documentTypeID" | sed -r 's/busdox-docid-qns::(.*)/\1/'
                    PLUTCNT=$(expr $PLUTCNT + 1)
                done
            else
                echo "No document types."
            fi
        else
            echo "No result."
        fi
    fi
elif [[ "$PLUTOPT" = "elma" ]] || [[ "$PLUTOPT" = "e" ]] && [[ -n $PLUTSRC ]]; then
    # ELMA
    PLUTAPI=$(curl -s "https://hotell.difi.no/api/json/difi/elma/participants?query=$PLUTSRC")
    PLUTPST=$(echo "$PLUTAPI" | jq -r '.posts')
    if [[ $PLUTPST -gt "0" ]]; then
        PLUTCNT=0
        PLUTPOS=0
        # echo "[ELMA]"
        until [[ "$PLUTCNT" = "$PLUTPST" ]]; do
            PLUTCNT=$(expr $PLUTCNT + 1)
            echo "$PLUTAPI" | jq -r ".entries[$PLUTPOS].name"
            PLUTEIDP=$(echo "$PLUTAPI" | jq -r ".entries[$PLUTPOS].Icd")
            PLUTEIDS=$(echo "$PLUTAPI" | jq -r ".entries[$PLUTPOS].identifier")
            echo "$PLUTEIDP:$PLUTEIDS"
            PLUTTYP=$(echo "$PLUTAPI" | jq -r ".entries[$PLUTPOS].PEPPOLBIS_3_0_BILLING_01_UBL")
            if [[ "$PLUTTYP" = "Ja" ]]; then
                echo "EHF 3.0"
            fi
            PLUTTYP=$(echo "$PLUTAPI" | jq -r ".entries[$PLUTPOS].EHF_INVOICE_2_0")
            if [[ "$PLUTTYP" = "Ja" ]]; then
                echo "EHF 2.0 (invoice)"
            fi
            PLUTTYP=$(echo "$PLUTAPI" | jq -r ".entries[$PLUTPOS].EHF_CREDITNOTE_2_0")
            if [[ "$PLUTTYP" = "Ja" ]]; then
                echo "EHF 2.0 (credit)"
            fi
            PLUTPOS=$(expr $PLUTPOS + 1)
            if [[ $PLUTPST -ge "2" ]] && [[ "$PLUTCNT" != "$PLUTPST" ]]; then
                echo ""
            fi
        done
    else
        echo "No result."
    fi
elif [[ "$PLUTOPT" = "dir" ]] || [[ "$PLUTOPT" = "d" ]] && [[ -n $PLUTSRC ]]; then
    # https://directory.peppol.eu/public/locale-en_US/menuitem-docs-rest-api
    PLUTCHK=$(echo $PLUTSRC | grep -E '^[0-9]{4}:.*$')
    if [[ -n $PLUTCHK ]]; then
        PLUTAPI=$(curl -s "https://directory.peppol.eu/search/1.0/json?participant=iso6523-actorid-upis::$PLUTSRC")
        PLUTPST=$(echo "$PLUTAPI" | jq -r '."total-result-count"')
        if [[ $PLUTPST -gt "0" ]]; then
            # echo "[PEPPOL Directory]"
            echo "$PLUTAPI" | jq -r '.matches[].entities[].name[].name'
            echo "$PLUTAPI" | jq -r '.matches[].participantID.value'
        else
            echo "No result."
        fi
    elif [[ -z $PLUTCHK ]]; then
        PLUTAPI=$(curl -s "https://directory.peppol.eu/search/1.0/json?q=$PLUTSRC")
        PLUTPST=$(echo "$PLUTAPI" | jq -r '."total-result-count"')
        if [[ $PLUTPST -gt "0" ]]; then
            PLUTCNT=0
            PLUTPOS=0
            # echo "[PEPPOL Directory]"
            until [[ "$PLUTCNT" = "$PLUTPST" ]]; do
                PLUTCNT=$(expr $PLUTCNT + 1)
                echo "$PLUTAPI" | jq -r ".matches[$PLUTPOS].entities[].name[].name"
                echo "$PLUTAPI" | jq -r ".matches[$PLUTPOS].participantID.value"
                PLUTPOS=$(expr $PLUTPOS + 1)
                if [[ $PLUTPST -ge "2" ]] && [[ "$PLUTCNT" != "$PLUTPST" ]]; then
                    echo ""
                fi
            done
        else
            echo "No result."
        fi
    fi
else
    echo "$PLUTNAM v$PLUTVER"
    echo ""
    echo "search 0192:987654321"
    echo "elma 987654321"
    echo "dir 0192:987654321"
fi
