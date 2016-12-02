#!/usr/bin/env bash
# ame.sh for macOS on iTerm2

function ame_init() {
    deps=(curl convert)
    for d in $deps; do
        if ! type $d > /dev/null 2>&1; then
            echo "$d not found"
            exit 1
        fi
    done
    if [ ! -d ~/.ame ]; then
        mkdir -p ~/.ame
        mkdir -p ~/.ame/tmp
    fi
    if [ ! -f ~/.ame/map000.pnm ]; then
        convert http://tokyo-ame.jwa.or.jp/map/map000.jpg ~/.ame/map000.pnm
    fi
    if [ ! -f ~/.ame/msk000.png ]; then
        curl -s -o ~/.ame/msk000.png http://tokyo-ame.jwa.or.jp/map/msk000.png
    fi
    if [ ! -f ~/.ame/base.png ]; then
        convert ~/.ame/map000.pnm ~/.ame/msk000.png -gravity south -compose over -composite ~/.ame/base.png
    fi
}

function ame_create() {
    SIZE="640x"
    TIME=$1
    LABEL=${TIME:8:2}:${TIME:10}
    URI=http://tokyo-ame.jwa.or.jp/mesh/000/${TIME}.gif
    convert ~/.ame/base.png $URI \
            -gravity south -undercolor white \
            -stroke gray -pointsize 26 -annotate 0 " $LABEL " \
            -compose over -composite ~/.ame/tmp/$LABEL.png
}

function ame_print() {
    convert -layers optimize -delay 50 ~/.ame/tmp/*.png ~/.ame/tmp/ame.gif
    cat ~/.ame/tmp/ame.gif|imgcat
    rm -f ~/.ame/tmp/*.png
}

function ame_last() {
    LAST=`curl -s http://tokyo-ame.jwa.or.jp/scripts/mesh_index.js \
          |grep -o -E '([0-9])+'|head -1`
    ame_create "${LAST}"
}

function ame_play() {
    LENGTH=13
    INDEX=`curl -s http://tokyo-ame.jwa.or.jp/scripts/mesh_index.js \
         |grep -o -E '([0-9])+'|head -$LENGTH`
    NOW=0
    for t in $INDEX; do
        TIMES+=( ${t} )
        ame_create $t
        B=""
        for i in `seq 1 $LENGTH`
        do
            if [ $NOW -eq $i ]
            then
                B="$B>"
            else
                if [ $i -le $NOW ]
                then
                    B="$B-"
                else
                    B="$B "
                fi
            fi
        done
        P=`expr $NOW \* 100 / $LENGTH`
        echo -en " loading...  [$B] $P %\r"
        NOW=`expr $NOW + 1`
    done
}

function usage() {
    echo "Usage: $0 [--play]" 1>&2
    exit 1
}

while getopts :h:play opt
do
    case $opt in
        h)
            usage
            ;;
        p)
            ame_init
            ame_play
            ame_print
            exit
            ;;
    esac
done

ame_init
ame_last
ame_print
