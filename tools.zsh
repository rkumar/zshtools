#!/usr/bin/env zsh
ZFM_DIR=${ZFM_DIR:-~/bin}
# Created: 2012-12-10 - 18:30 
# TODO make a set of methods in a file to be sourced
# that return files for a query. then use these in various utils
# today() hour() week() old() small() zero() large() huge() larger_than etc
# one that gives a list to choose for interactive, others for piping
# testing out menu.zsh, i can also create a function

# this is gls in my functions.zsh, does a quick local search and does not go
# into pull requests which take ages
mybs(){  =ls /usr/local/Library/Formula/ | grep $1 | sed 's/\.rb$//g' | sort }

sl() {
    ~/bin/sl | $PAGER
}
b_all() {
    tar zcvf $arch *~(*.bz2|*.gz|*.tgz|*.zip|*.z)(.)
}
b_today() {
    #arch="arch${x}_${ddate}.tgz"
    # file with spces will not get zipped XXX
    tar zcvf $arch $(today --nozip)
}
b_week() {
    #arch="arch${x}_${ddate}.tgz"
    tar zcvf $arch $(newerthan --nozip 6)
}
b_month() {
    #arch="arch${x}_${ddate}.tgz"
    tar zcvf $arch $(newerthan --nozip 31)
}
b_hour() {
    ddate=$(date +%Y%m%d_%H%M)
    arch="arch${x}_${ddate}.tgz"
    files=(**/*(ND.mh-1))
    (( $#files > 0 )) && tar zcvf $arch $(print -rl -- $files)
}
backup...() {
    # ouch this may not be in the ZFM dir if you keep a separate dir for ZFM
    #source $ZFM_DIR/files.zsh
    source ~/bin/files.zsh
    ddate=$(date +%Y%m%d_%H%M)
    arch="arch${x}_${ddate}.tgz"
    menu_loop ">Backup Menu" "today week month hour all" "twmha"
    [[ -n "$menu_text" ]] && {
        eval "b_${menu_text}"
        [ -f "$arch" ] && {
            ls -l $arch
            [[ -n "$MAILID" ]] && {
               # if you have set MAILID and have your mail running (msmtp / postfix)
               # then you can send this file as a backup to your gmail
               # Requires mpack also
                echo -n "Mail Backup $arch [yn]?: "
                read -q yn
                echo
                #[[ $yn =~ [Yy] ]] && mailbackup.sh $arch
                [[ $yn =~ [Yy] ]] && mpack -s "backup: $arch" "$arch" "$MAILID"
            }
        }
    }
}
brew...(){
    while (true); do
        menu_loop ">Brew Menu" "outdated upgrade update list doctor missing cleanup ls search versions" "oupldmc sv"
        case $menu_text in
            "outdated"|"update"|"doctor"|"list"|"missing")
                brew $menu_text
                pause
                ;;
            "upgrade")
                oper=$menu_text
                # remove versions and join into one line
                files=$(brew outdated | cut -f 1 | tr '\n\r' '  ')
                if [[ $#files > 0 ]]; then
                    menu_loop ">Upgrade Menu" "$files"
                    formula=$menu_text
                    [[ -n "$formula" ]] && brew $oper "$formula" 
                else
                    echo "Nothing outdated"
                fi
                ;;
            "cleanup")
                oper=$menu_text
                files=$(brew list --versions | grep ' [^ ]* ')
                if [[ $#files > 0 ]]; then
                    echo "$files"
                    echo
                    ff=$(echo "$files" | cut -f 1 -d ' ' | tr '\n\r' '  ')
                    menu_loop ">Cleanup Menu" "$ff"
                    formula=$menu_text
                    [[ -n "$formula" ]] && brew $oper "$formula" 
                else
                    echo "Nothing to cleanup"
                fi
                    ;;
            "search")
                echo -n "pattern: "
                read formula
                [[ -n "$formula" ]] && brew $menu_text "$formula" 
                ;;
            "ls")
                    #source ~/functions.zsh 
                    echo -n "pattern: "
                    read formula
                    [[ -n "$formula" ]] && { mybs "$formula" ;  pause }
                ;;
            "versions")
                brew list --versions | $PAGER
                pause
                ;;
            *) break
                ;;
        esac
    done
}
git...(){
    while (true); do
        menu_loop ">Git Menu" "push newbranch mergebranch list newtag"  "pnmlt"
        case $menu_text in
            "push")
                gitpush
                ;;
            "newbranch")
                vared -c -p "Enter Branch Name: " branch
                git checkout -b $branch
                ;;
            "mergebranch")
                branch=master
                vared -c -p "Enter Target Branch Name: " branch
                source=$(git rev-parse --abbrev-ref HEAD)
                vared -c -p "Enter Source Branch Name: " source
                print "Going to merge $source into $branch. OK?"
                read
                git checkout $branch
                git merge $source
                ;;
            "list")
                git branch
                ;;
            "newtag")
                vared -c -p "Enter tag name: " tagname
                tagdesc="Release $tagname"
                vared -c -p "Enter tag description: " tagdesc
                ## prepends a 'v' to tagname e.g. v1.1
                git tag -a -m $tagdesc v$tagname
                ;;
            *) break
                ;;
        esac
    done
}
rb() {
    echo $PATH
    which ruby
    ruby --version
    #rvm list
}
remspace() {
    echo "Listing files with spaces in filename"
    print -rl -- *\ *
    echo -n "Replace spaces from filenames with underscores [yn]?: "
    read -q yn
    echo
    [[ $yn =~ [Yy] ]] && {
        autoload zmv
        zmv '* *' '$f:gs/ /_'
        echo Done
        echo Checking for spaces in filenames again
        print -rl -- *\ *
    }
}
changesuffix() {
    # Change the suffix from *.sh to *.pl
    echo "Change files of one suffix to another suffix"
    echo 'Change *.txt to *.doc'
    local suffixpre="*.from"
    local suffixpost="*.to"
    vared -p "Enter existing filespec (e.g: *.txt): " suffixpre
    [[ -z $suffixpre ]] && break
    vared -p "Enter target (new) filespec (e.g: *.doc): " suffixpost 
    [[ -z $suffixpost ]] && break
    autoload zmv
    zmv -W $suffixpre $suffixpost
    # ----
    #  For more complex changes like some files use hold pattern
    #  zmv  '(1*).txt' '$1.TEXT'

}
gdc() {
    echo $PATH
    #[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # This loads RVM into a shell session.
    gdc.rb

}
others...(){ 
    menu_loop ">Others Menu" "mc gdc tig sl tigs remspace changesuffix" "mgts r"
    if [[ "$menu_text" = "tigs" ]]; then
        tig status
    elif [[ -n "$menu_text" ]]; then
        ${menu_text}
        #eval "${menu_text}"
    fi
}
OPT=${OPT:-"-l"}
export OPT

source ${ZFM_DIR}/zfm_menu.zsh

while (true); do
    menu_loop "Options Menu" "v vifm ranger vshnu list listquery backup... others... brew... git..." "v r l zobg"
    [[ -z "$menu_text" ]] && { echo "bye" ; exit }
    $menu_text
done
