#!/bin/bash
# plut v0.1
# Made by Dr. Waldijk
# PEPPOL Look-Up Tool.
# Read the README.md for more info.
# By running this script you agree to the license terms.
# Config ----------------------------------------------------------------------------
PLUTNAM="plut"
PLUTVER="0.1"
PLUTNET=$1
PLUTOPT=$2
PLUTSRC="$3 $4 $5 $6 $7 $8 $9"
PLUTSRC=$(echo $PLUTSRC | sed -r 's/ /%20/g')
# Functions -------------------------------------------------------------------------
# -----------------------------------------------------------------------------------
if [[ "$PLUTNET" = "elma" ]]; then
    if [[ "$PLUTOPT" = "search" ]] && [[ -n $PLUTSRC ]]; then
        PLUTAPI=$(curl -s "https://hotell.difi.no/api/json/difi/elma/participants?query=$PLUTSRC")
        PLUTPST=$(echo "$PLUTAPI" | jq -r '.posts')
        if [[ $PLUTPST -gt "0" ]]; then
            PLUTCNT=0
            PLUTPOS=0
            until [[ "$PLUTCNT" = "$PLUTPST" ]]; do
                PLUTCNT=$(expr $PLUTCNT + 1)
                echo "$PLUTAPI" | jq -r ".entries[$PLUTPOS].name"
                PLUTEIDP=$(echo "$PLUTAPI" | jq -r ".entries[$PLUTPOS].Icd")
                PLUTEIDS=$(echo "$PLUTAPI" | jq -r ".entries[$PLUTPOS].identifier")
                echo "$PLUTEIDP:$PLUTEIDS"
                echo "$PLUTAPI" | jq -r ".entries[$PLUTPOS].PEPPOLBIS_3_0_BILLING_01_UBL" | sed -r 's/(.*)/EHF 3.0: \1/'
                echo "$PLUTAPI" | jq -r ".entries[$PLUTPOS].EHF_INVOICE_2_0" | sed -r 's/(.*)/EHF 2.0 \(invoice\): \1/'
                echo "$PLUTAPI" | jq -r ".entries[$PLUTPOS].EHF_CREDITNOTE_2_0" | sed -r 's/(.*)/EHF 2.0 \(credit\): \1/'
                PLUTPOS=$(expr $PLUTPOS + 1)
                if [[ $PLUTPST -ge "2" ]] && [[ "$PLUTCNT" != "$PLUTPST" ]]; then
                    echo ""
                fi
            done
        else
            echo "No result."
        fi
    elif [[ "$PLUTOPT" = "check" ]] && [[ -n $PLUTSRC ]]; then
        # Load a CSV list
        PLUTCHK=$(echo $PLUTSRC | grep csv)
        if [[ -z "$PLUTCHK" ]]; then
            PLUTAPI=$(curl -s "https://hotell.difi.no/api/json/difi/elma/participants?query=$PLUTSRC")
            PLUTRST=$(echo "$PLUTAPI" | jq -r '.posts')
            if [[ "$PLUTRST" = "0" ]]; then
                echo "$PLUTSRC - Nope!"
            elif [[ "$PLUTRST" != "0" ]]; then
                echo "$PLUTSRC - Yup!"
            else
                echo "No idea..."
            fi
        fi
    else
        echo "$PLUTNAM v$PLUTVER"
        echo ""
        echo "elma search 987654321"
        echo "elma search Company Name"
        echo "elma check 987654321"
    fi
elif [[ "$PLUTNET" = "dir" ]]; then
    if [[ "$PLUTOPT" = "lookup" ]] && [[ -n $PLUTSRC ]]; then
        PLUTAPI=$(curl -s "https://directory.peppol.eu/search/1.0/json?participant=iso6523-actorid-upis::$PLUTSRC")
        echo "$PLUTAPI" | jq -r '.matches[].entities[].name[].name'
    elif [[ "$PLUTOPT" = "check" ]] && [[ -n $PLUTSRC ]]; then
        # Load a CSV list
        PLUTCHK=$(echo $PLUTSRC | grep csv)
        if [[ -z "$PLUTCHK" ]]; then
            PLUTAPI=$(curl -s "https://directory.peppol.eu/search/1.0/json?participant=iso6523-actorid-upis::$PLUTSRC")
            PLUTRST=$(echo "$PLUTAPI" | jq -r '."total-result-count"')
            if [[ "$PLUTRST" = "0" ]]; then
                echo "$PLUTSRC - Nope!"
            elif [[ "$PLUTRST" != "0" ]]; then
                echo "$PLUTSRC - Yup!"
            else
                echo "No idea..."
            fi
        fi
    elif [[ "$PLUTOPT" = "search" ]] && [[ -n $PLUTSRC ]]; then
        PLUTAPI=$(curl -s "https://directory.peppol.eu/search/1.0/json?q=$PLUTSRC")
        PLUTPST=$(echo "$PLUTAPI" | jq -r '."total-result-count"')
        if [[ $PLUTPST -gt "0" ]]; then
            PLUTCNT=0
            PLUTPOS=0
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
    else
        echo "$PLUTNAM v$PLUTVER"
        echo ""
        echo "pdir lookup 0192:987654321"
        echo "pdir check 0192:987654321"
        echo "pdir search Company Name"
    fi
else
    echo "$PLUTNAM v$PLUTVER"
fi
