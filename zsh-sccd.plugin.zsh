function sccd() {
    # set -x
    # echo 'running scc'
    local scc_stdout_csv=$("${SCCD_SCC_EXECUTABLE:-scc}" --by-file --format csv -- "$1")
    # echo 'scc done'


    # delete all "lines" top-level (key, value) pair in all .metadata.json
    # see https://unix.stackexchange.com/a/310553
    for meta_json in **/.metadata.json(N); do
        old_meta_json=$(cat "$meta_json")
        jq 'del(.[].programmingCode)' <<< "$old_meta_json" > "$meta_json"
    done

    # remove csv header
    res=$(echo $scc_stdout_csv | tail -n +2)
    echo $res | while read -r line; do

        # The order is:
        # 1. Language
        # 2. Location (relative filepath)
        # 3. Filename (basename)
        # 4. Lines (total)
        # 5. Code
        # 6. Comments
        # 7. Blanks
        # 8. Complexity
        # 9. Bytes

        # zsh defines path, so using path_
        local path_=$(command xsv select 2 <<< $line | sed 's/"\([^"]*\)"/\1/g')
        # echo 'path'
        # echo $path_
        local base=$(command xsv select 3 <<< $line | sed 's/"\([^"]*\)"/\1/g')
        # echo 'base'
        # echo $base
        local sloc=$(command xsv select 5 <<< $line)
        # echo 'sloc'
        # echo $sloc
        local init=$path_
        # echo 'init'
        # echo $init
        while [[ $init != '.' ]]; do
            # echo 'foo'
            # sanity check
            if [[ $init = '' ]]; then
                echo "An internal error occurred in \`sccd\`. The function is returning."
                return 1
            fi

            # inspired by Haskell's head ([0]), tail ([1:]), init ([:-1]), last ([-1:])
            local last=$(basename $init)
            local init=$(dirname $init)
            # path is directory
            if [[ -d "$init/.metadata.json" ]]; then
                if ![[ -z $SCCD_QUIET ]]; then
                    echo "$init/.metadata.json is a directory. Halting on file $patH"
                fi
                echo "An internal error occurred in `sccd`. The function is returning."
                return 1
            fi
            # path is not a file or symlink
            if [[ ! -f "$init/.metadata.json" ]]; then
                touch "$init/.metadata.json"
            fi
            # see https://github.com/stedolan/jq/issues/1142#issuecomment-432003984
            local JQ_ADD_TO_LINES='
                if . == [] then {} else .[] end
                | .[$last].programmingCode += 
            '"$sloc"
            # see https://unix.stackexchange.com/a/669512
            old_meta_json=$(command cat "$init/.metadata.json")
            jq -s --arg last "$last" "$JQ_ADD_TO_LINES" <<< "$old_meta_json" > "$init/.metadata.json" 
        done

    done

}

SCCD_ERROR_MSG_SCC_NOT_INSTALLED="✗ It seems that \`scc\` is not installed. You can refer to:\nhttps://github.com/boyter/scc/#install"
SCCD_ERROR_MSG_AWK_NOT_INSTALLED="✗ It seems that \`awk\` is not installed. You can probably install it with your package manager."

# ZSH_CUSTOM="/Users/dteiml/p/hacker-dom"

function sccd-doctor()
{
    local sccd_location="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-sccd/zsh-sccd.plugin.zsh";
    # file exists and is not empty
    if [[ -s "$sccd_location" ]]; then
        # variable is set to non-empty string
        if ![[ -z $SCCD_QUIET ]]; then
            echo "✔ sccd is located at: \`$sccd_location\`"
        fi
    fi
    # from https://stackoverflow.com/a/5203740/4204961
    if [[ ${plugins[(r)zsh-sccd]} == zsh-sccd ]]; then
        if ![[ -z $SCCD_QUIET ]]; then
            echo "✔ zsh-sccd is in oh-my-zsh's \`plugins\`"
        fi
    else
        if ![[ -z $SCCD_QUIET ]]; then
            echo "✗ zsh-sccd is NOT in oh-my-zsh's \`plugins\`. Make sure it's there, then start a new \`zsh\` session (or run \`exec zsh -l\`)"
            local fail=true
        fi
    fi
    # if ![[ -z $SCCD_QUIET ]]; then
    #     echo "✔ sccd is installed at ${BASH_SOURCE[0]}";
    # fi
    if command "${SCCD_SCC_EXECUTABLE:-scc}" --version &> /dev/null; then
        if ![[ -z $SCCD_QUIET ]]; then
            echo "✔ scc is installed"
        fi
    else
        if ![[ -z $SCCD_QUIET ]]; then 
            echo "$SCCD_ERROR_MSG_SCC_NOT_INSTALLED";
            local fail=true
        fi
    fi
    # command "${SCCD_SCC_EXECUTABLE:-awk}" --version &> /dev/null \
    #     && echo "✔ awk is installed" \
    #     || echo "$SCCD_ERROR_MSG_AWK_NOT_INSTALLED";
    # variable is unset or empty (string)
    if [[ -z $fail ]]; then
        exit 1;
    fi
}

# unset ZSH_CUSTOM
