#!/bin/bash
# plut v0.7
# Made by Dr. Waldijk
# PEPPOL Look-Up Tool.
# Read the README.md for more info.
# By running this script you agree to the license terms.
# Config ----------------------------------------------------------------------------
PLUTNAM="plut"
PLUTVER="0.7"
PLUTNET=$1
PLUTOPT=$2
PLUTSRC="$3 $4 $5 $6 $7 $8 $9"
PLUTSRC=$(echo $PLUTSRC | sed -r 's/ /%20/g')
# Functions -------------------------------------------------------------------------
#doctyp () {
#    x
#}
# -----------------------------------------------------------------------------------
if [[ "$PLUTNET" = "elma" ]] || [[ "$PLUTNET" = "e" ]]; then
    if [[ "$PLUTOPT" = "search" ]] || [[ "$PLUTOPT" = "s" ]] && [[ -n $PLUTSRC ]]; then
        PLUTAPI=$(curl -s "https://hotell.difi.no/api/json/difi/elma/participants?query=$PLUTSRC")
        PLUTPST=$(echo "$PLUTAPI" | jq -r '.posts')
        if [[ $PLUTPST -gt "0" ]]; then
            PLUTCNT=0
            PLUTPOS=0
            echo "[ELMA]"
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
    elif [[ "$PLUTOPT" = "check" ]] || [[ "$PLUTOPT" = "c" ]] && [[ -n $PLUTSRC ]]; then
        # Load a CSV list
        PLUTFIL=$PLUTSRC
        PLUTCHK=$(echo $PLUTFIL | grep csv)
        PLUTCNT=0
        PLUTLIN=$(cat $PLUTFIL | tr ',' '\n' | wc -l)
        echo "[ELMA]"
        if [[ -n "$PLUTCHK" ]]; then
            until [[ "$PLUTCNT" = "$PLUTLIN" ]]; do
                PLUTCNT=$(expr $PLUTCNT + 1)
                PLUTSRC=$(cat $PLUTFIL | cut -d , -f $PLUTCNT)
                PLUTAPI=$(curl -s "https://hotell.difi.no/api/json/difi/elma/participants?query=$PLUTSRC")
                PLUTRST=$(echo "$PLUTAPI" | jq -r '.posts')
                if [[ "$PLUTRST" = "0" ]]; then
                    echo "$PLUTSRC - Nope!"
                elif [[ "$PLUTRST" != "0" ]]; then
                    echo "$PLUTSRC - Yup!"
                else
                    echo "No idea..."
                fi
                sleep 0.5s
            done
        else
            echo "No csv found"
        fi
    else
        echo "$PLUTNAM v$PLUTVER"
        echo ""
        echo "elma search 987654321"
        echo "elma search Company Name"
        echo "elma check list.csv"
    fi
elif [[ "$PLUTNET" = "helger" ]] || [[ "$PLUTNET" = "h" ]]; then
    # https://peppol.helger.com/public/locale-en_US/menuitem-tools-rest-api
    if [[ "$PLUTOPT" = "search" ]] || [[ "$PLUTOPT" = "s" ]] && [[ -n $PLUTSRC ]]; then
        PLUTCHK=$(echo $PLUTSRC | grep -E '^[0-9]{4}:.*$')
        if [[ -n $PLUTCHK ]]; then
            PLUTAPI=$(curl -s "https://peppol.helger.com/api/smpquery/digitprod/iso6523-actorid-upis::$PLUTSRC")
            PLUTDAP=$PLUTAPI
            PLUTCHK=$(echo $PLUTAPI | grep -o 'HTTP Status 404' | head -n 1)
            if [[ -z $PLUTCHK ]] && [[ -n $PLUTAPI ]]; then
                echo "[PEPPOL @ Helger]"
                echo $PLUTAPI | jq -r '.participantID' | sed -r 's/iso6523-actorid-upis::(.*)/\1/'
                PLUTCNT=0
                while :; do
                    PLUTCHK=$(echo $PLUTDAP | jq -r ".urls[$PLUTCNT].documentTypeID" | grep 'Invoice')
                    PLUTCNT=$(expr $PLUTCNT + 1)
                    if [[ -n $PLUTCHK ]]; then
                        #echo ""
                        break
                    fi
                done
                PLUTDOC=$(echo $PLUTCHK | sed -r "s/#/%23/g")
                PLUTDAP=$(curl -s "https://peppol.helger.com/api/smpquery/digitprod/iso6523-actorid-upis::$PLUTSRC/$PLUTDOC")
                echo $PLUTDAP | jq -r '.serviceinfo.processes[].endpoints[].serviceDescription'
                echo $PLUTDAP | jq -r '.serviceinfo.processes[].endpoints[].technicalContactUrl'
                echo ""
                PLUTCNT=0
                while :; do
                    PLUTCHK=$(echo $PLUTAPI | jq -r ".urls[$PLUTCNT].documentTypeID")
                    if [[ "$PLUTCHK" = "null" ]]; then
                        break
                    fi
                    if [[ "$PLUTCHK" != "null" ]] && [[ "$PLUTCNT" != "0" ]]; then
                        echo ""
                    fi
                    echo $PLUTAPI | jq -r ".urls[$PLUTCNT].documentTypeID" | sed -r 's/(.*)/\1/'
                    PLUTCNT=$(expr $PLUTCNT + 1)
                done
            else
                echo "No result."
            fi
        fi
    else
        echo "$PLUTNAM v$PLUTVER"
        echo ""
        echo "helger search 0192:987654321"
        # echo "helger check list.csv"
    fi
elif [[ "$PLUTNET" = "dir" ]] || [[ "$PLUTNET" = "d" ]]; then
    # https://directory.peppol.eu/public/locale-en_US/menuitem-docs-rest-api
    if [[ "$PLUTOPT" = "search" ]] || [[ "$PLUTOPT" = "s" ]] && [[ -n $PLUTSRC ]]; then
        PLUTCHK=$(echo $PLUTSRC | grep -E '^[0-9]{4}:.*$')
        if [[ -n $PLUTCHK ]]; then
            PLUTAPI=$(curl -s "https://directory.peppol.eu/search/1.0/json?participant=iso6523-actorid-upis::$PLUTSRC")
            PLUTPST=$(echo "$PLUTAPI" | jq -r '."total-result-count"')
            if [[ $PLUTPST -gt "0" ]]; then
                echo "[PEPPOL Directory]"
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
                echo "[PEPPOL Directory]"
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
    elif [[ "$PLUTOPT" = "check" ]] || [[ "$PLUTOPT" = "c" ]] && [[ -n $PLUTSRC ]]; then
        # Load a CSV list
        PLUTFIL=$PLUTSRC
        PLUTCHK=$(echo $PLUTFIL | grep csv)
        PLUTCNT=0
        PLUTLIN=$(cat $PLUTFIL | tr ',' '\n' | wc -l)
        if [[ -n "$PLUTCHK" ]]; then
            echo "[PEPPOL Directory]"
            until [[ "$PLUTCNT" = "$PLUTLIN" ]]; do
                PLUTCNT=$(expr $PLUTCNT + 1)
                PLUTSRC=$(cat $PLUTFIL | cut -d , -f $PLUTCNT)
                PLUTAPI=$(curl -s "https://directory.peppol.eu/search/1.0/json?participant=iso6523-actorid-upis::$PLUTSRC")
                PLUTRST=$(echo "$PLUTAPI" | jq -r '."total-result-count"')
                if [[ "$PLUTRST" = "0" ]]; then
                    echo "$PLUTSRC - Nope!"
                elif [[ "$PLUTRST" != "0" ]]; then
                    echo "$PLUTSRC - Yup!"
                else
                    echo "No idea..."
                fi
                sleep 0.5s
            done
        else
            echo "No csv found"
        fi
    else
        echo "$PLUTNAM v$PLUTVER"
        echo ""
        echo "dir search 0192:987654321"
        echo "dir search Company Name"
        echo "dir check list.csv"
    fi
else
    echo "$PLUTNAM v$PLUTVER"
    echo ""
    echo "elma"
    echo "helger"
    echo "dir"
fi
