#!/usr/bin/env zsh
# ----------------------------------------------------------------------------- #
#         File: drill.zsh
#  Description: Allow caller to drill down a list given, usually file names
#       Author: rkumar http://github.com/rkumar/rbcurse/
#         Date: 2012-12-25 - 12:39
#      License: Freeware / GPL
#  Last update: 2012-12-25 19:04
# ----------------------------------------------------------------------------- #

# not sure whether i should come out immediately when one gets selected or remain 
# in there so user can explicitly say select and maybe select more
# Usage will define how this goes
#
export COLOR_DEFAULT="\\033[0m"
export COLOR_RED="\\033[1;31m"
export COLOR_GREEN="\\033[1;32m"
export COLOR_BOLD="\\033[1m"
export COLOR_BOLDOFF="\\033[22m"
ZFM_PAGE_KEY=' '
ZFM_RESET_PATTERN_KEY='.'
ZFM_SELECT_KEY='@'
ZFM_QUIT_KEY='q'
ZFM_EXIT_KEY='q'
MFM_NLIDX="TODO XXX123..a-z..A-Z"
PAGESZ=59     # used for incrementing while paging
(( PAGESZ1 = PAGESZ + 1 ))
_drill() {
    selection="" # contains return value if anything chosen
    local width=30
    local title=$1
    shift
    local viewport vpa fin
    myopts=("${(@f)$(print -rl -- $@)}")
    local cols=3
    local tot=$#myopts
    local sta=1
    local resetpatt="" # when we need to reset the patt use this, so if we move to grep
    local patt
    #local patt="."
    patt="$resetpatt"
    while (true)
    do
        (( fin = sta + $PAGESZ )) # 60
        [[ $fin -gt $tot ]] && fin=$tot
        #viewport=$(print -rl -- $myopts  | grep "$patt")
        if [[ -z $M_MATCH_ANYWHERE ]]; then
            viewport=(${(M)myopts:#$patt*})
        else
            viewport=(${(M)myopts:#*$patt*})
        fi
        # this line replaces the sed filter
        viewport=(${viewport[$sta, $fin]})
        vpa=("${(@f)$(print -rl -- $viewport)}")
        local ttcount=$#vpa
        if [[ $ttcount -lt 15 ]]; then
            cols=1
            width=80
        elif [[ $ttcount -lt 40 ]]; then
            cols=2
            width=40
        else
            cols=3
            width=30
        fi
        [[ $fin -gt $tot ]] && fin=$tot
        local sortorder=""
        [[ -n $ZFM_SORT_ORDER ]] && sortorder="o=$ZFM_SORT_ORDER"
        print_title "$title $sta to $fin of $tot ${COLOR_GREEN}$sortorder $ZFM_STRING${COLOR_DEFAULT}"
        # #
        #  Both nl1 and print_files need to have the item name and both modify the output
        #  one adds a number the other colors it. So the second one is unable to function
        #  correctly
        # # 
        print -rC$cols $(print_files $viewport | nl1.sh -p "$patt" | tr " " "" ) | tr -s "" |  tr "" " " 
        #print -rC$cols $(print_files $viewport | nl1.sh -p "$patt" | cut -c-$width | tr "[ \t]" "?"  ) | tr -s "" |  tr "" " " 
        #print -rC$cols $(print -rl -- $viewport | nl1.sh -p "$patt" | cut -c-$width | tr "[ \t]" "?"  ) | tr -s "" |  tr "" " " 
        echo -n "$patt > "
        bindkey -s "OD" ","
        bindkey -s "OA" "~"
        read -k -r ans
        echo
        clear # trying this out
        [[ $ans = $'\t' ]] && perror "Got a TAB XXX"
        [[ $ans = "" ]] && perror "Got a ESC XXX"
        case $ans in
            "")
                # BLANK blank
                (( sta = 1 ))
                patt="$resetpatt"
                ;;
            $ZFM_PAGE_KEY)
                # SPACE space, however may change to ENTER due to spaces in filenames
                (( sta += $PAGESZ1 ))
                [[ $fin -gt $tot ]] && fin=$tot
                ;;
            $ZFM_SELECT_KEY)
                _select_all
                break
                ;;
            [1-9])
                # KEY PRESS key
                if [[ -n "$M_FULL_INDEXING" ]]; then
                    iix=$MFM_NLIDX[(i)$ans]
                    pinfo "got iix $iix for $ans"
                    [[ -n "$iix" ]] && selection=$vpa[$iix]
                    pinfo "selection was $selection"
                else

                (( ix = sta + $ans - 1))
                selection=""
                #vpa=( $(print -rl -- $viewport) )
                [[ -n $M_VERBOSE ]] && perror "files shown $#vpa "
                if [[ $ttcount -gt 9 ]]; then
                    if [[ $patt = "" ]]; then
                        npatt="${ans}*"
                    else
                        npatt="$patt$ans"
                    fi
                    if [[ -n "$M_SWITCH_OFF_DUPL_CHECK" ]]; then
                        lines=$(check_patt $npatt)
                        ct=$(print -rl -- $lines | wc -l)
                    else
                        ct=0
                    fi
                    [[ -n $lines ]] || ct=0
                    [[ -n $M_VERBOSE ]] && perror "comes here $ct , $lines"
                    if [[ $ct -eq 1 ]]; then
                        [[ -n "$lines" ]] && { selection=$lines; break }
                    elif [[ $ct -eq 0 ]]; then
                        selection=$vpa[$ans]
                        [[ -n $M_VERBOSE ]] && echo " selected $selection"
                    else
                        patt=$npatt
                    fi
                else
                    # there are only 9 or less so just use mnemonics, don't check
                    # earlier
                    selection=$vpa[$ans]
                    echo " 1. selected $selection"
                fi
            fi # M_FULL
                [[ -n "$selection" ]] && break
                ;;
            ","|"+"|"~"|":"|"\`"|"@"|"%"|"#")
                # we break these keys so caller can handle them, other wise they
                # get unhandled PLACE SWALLOWED keys here to handle
                # go down to MARK1 section to put in handling code
                [[ -n $M_VERBOSE ]] && perror "breaking here with $ans"
                break
                ;;
            "^")
                # if you press this anywhere while typing it will toggle ^
                toggle_match_from_start
                ;;
            $ZFM_QUIT_KEY)
                break
                ;;
            $ZFM_EXIT_KEY)
                break
                ;;
            [a-zA-Z_0\.\ ])
                ## UPPER CASE upper section alpha characters
                (( sta = 1 ))

                if [[ -n "$M_FULL_INDEXING" ]]; then
                    iix=$MFM_NLIDX[(i)$ans]
                    pinfo "iix was $iix for $ans"
                    [[ -n "$iix" ]] && { selection=$vpa[$iix]; break }
                    pinfo "selection was $selection"

                else

                    if [[ $patt = "" ]]; then
                        [[ $ans = '.' ]] && { 
                        # i will be doing this each time dot is pressed
                        # ad changing setting for calling shell too ! XXX
                        echo "I should only set and do this if nothing is showing of its off"
                        pbold "Setting glob_dots ..."
                        setopt GLOB_DOTS
                        #setopt globdots
                        param=$(eval "print -rl -- ${pattern}(${MFM_LISTORDER}$filterstr)")
                        myopts=("${(@f)$(print -rl -- $param)}")
                        pbold "count is $#myopts"
                    }
                        patt="${ans}"
                    else
                        [[ -n $M_VERBOSE ]] && perror "comes here 1"

                        patt="$patt$ans"
                    fi
                    pinfo "Pattern is $patt "
                    [[ -n $M_VERBOSE ]] && echo "Pattern IS :$patt:"
                    [[ -n $M_VERBOSE ]] && perror "sending $patt to chcek"
                    # if there's only one file for that char then just jump to it
                    lines=$(check_patt $patt)
                    ct=$(print -rl -- $lines | wc -l)
                    #perror "comes here $ct , $lines"
                    if [[ $ct -eq 1 ]]; then
                        [[ -n "$lines" ]] && { selection=$lines; break }
                    fi
                fi # M_FULL
                ;;
            "$ZFM_RESET_PATTERN_KEY")
                patt="$resetpatt"
                ;;

            *) echo "default got :$ans:"
                (( sta = 1 ))
                ## a case within a case for the same var -- how silly
                case $ans in
                    "")
                        # backspace if we are filtering, if blank and still backspace then put start of line char
                        if [[ $patt = "" ]]; then
                            patt=""
                        else
                            # backspace if we are filtering, remove last char from pattern
                            patt=${patt[1,${#patt}-1]}
                        fi
                        ;;
                    ".")
                        # reset the patter when pressing ,
                        patt="$resetpatt"
                        ;;
                    *)
                        [[ "$ans" == "[" ]] && echo "got ["
                        [[ "$ans" == "{" ]] && echo "got {"
                        perror "Key $ans unhandled and swallowed"
                        #  put key in SWALLOW section to pass to caller
                        patt="$resetpatt"
                        ;;
                esac
                [[ -n $M_VERBOSE ]] && echo "Pattern is :$patt:"
        esac
        [[ $sta -ge $tot ]] && break
        # break takes control back to MARK1 section below

    done
    echo $selection
    [[ -n "$selection" ]] && {
        if [[ $selected[(i)$selection] -gt $#selected ]]; then
           selected=(
           $selected
           $selection
           )
       else
           selected[(i)$selection]=()
       fi

    }
}
typeset -U selected
selected=()
del=$''
print_files() {
let c=1
    for f
    do
        if [[ $selected[(i)$f] -gt $#selected ]]; then
            echo "$f"
        else
            echo "$COLOR_BOLD$f$COLOR_DEFAULT"
        fi
        let c++
    done
}
check_patt() {

        patt=$1
        # now we only check within the given array, no looking at dir listing since
        # the data could be anything
        local chk
        if [[ -z $M_MATCH_ANYWHERE ]]; then
            chk=(${(M)myopts:#$patt*})
        else
            chk=(${(M)myopts:#*$patt*})
        fi
        print -rl -- $chk

}
toggle_match_from_start() {
    # default is unset, it matches what you type from start
    if [[ -z "$M_MATCH_ANYWHERE" ]]; then
        M_MATCH_ANYWHERE=1
    else
        M_MATCH_ANYWHERE=
    fi
    export M_MATCH_ANYWHERE
}
_multiselect() {
    local title="$1"
    typeset -U selected_items
    selected_items=()
    shift
    # drill down should allow selection of all in view using @ TODO
    # selected items should be shown highlighted or something
    # so multi has to be part of the main thing
    while (true)
    do
        local ct=$#selected
        _drill "$title ($ct)" $@
        [[ "$ans" == $ZFM_QUIT_KEY ]] && break
        # next line fails if multiple selection
        #[[ -z "$selection" ]] && { break }
        # select all puts into selected
        [[ -n "$selection" ]] && {
            selected_items=(
            $selected_items
            $selection
            )
        }

    done
    print -rl -- $selected_items


}
#  selects all in the current view
_select_all() {
    for fs in $viewport
    do
            selected=(
            $selected
            $fs
            )
    done
}
source ~/bin/menu.zsh
_multiselect "Directory Listing $PWD" $@
#_drill "Directory Listing $PWD" $@
