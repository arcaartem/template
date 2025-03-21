#!/bin/sh

# Configuration
set -e
INCLUDE_PREFIX="@include"
IF_PREFIX="@if"
ENDIF_TOKEN="@endif"
ELSE_TOKEN="@else"

# Error handling
die() {
    echo "Error: $1" >&2
    exit 1
}

show_usage() {
    echo "Usage: $0 template_file [var1=value1 var2=value2 ...]"
    exit 1
}

# Variable handling
process_variables() {
    for arg in "$@"; do
        case "$arg" in
            *=*) eval "export $arg" ;;
        esac
    done
}

# String manipulation utilities
trim() {
    local str="$1"
    str="${str#"${str%%[![:space:]]*}"}"  # trim leading
    str="${str%"${str##*[![:space:]]}"}"  # trim trailing
    printf '%s' "$str"
}

starts_with() {
    case "$1" in
        "$2"*) return 0 ;;
        *) return 1 ;;
    esac
}

# Template processing functions
process_subshell() {
    local cmd="$1"
    eval "$cmd"
}

process_variable() {
    local var_name="$1"
    eval "printf '%s' \"\$$var_name\""
}

expand_vars() {
    local line="$1"
    local result=""
    local in_var=0
    local in_subshell=0
    local var_name=""
    local subshell_cmd=""
    
    while [ -n "$line" ]; do
        case "$line" in
            '$('*)
                in_subshell=1
                subshell_cmd=""
                line="${line#\$\(}"
                ;;
            ')'*)
                if [ $in_subshell -eq 1 ]; then
                    in_subshell=0
                    result="$result$(process_subshell "$subshell_cmd")"
                    line="${line#\)}"
                fi
                ;;
            '${'*)
                if [ $in_subshell -eq 0 ]; then
                    in_var=1
                    var_name=""
                    line="${line#\$\{}"
                fi
                ;;
            '}'*)
                if [ $in_subshell -eq 0 ] && [ $in_var -eq 1 ]; then
                    in_var=0
                    result="$result$(process_variable "$var_name")"
                    line="${line#\}}"
                fi
                ;;
            *)
                if [ $in_var -eq 1 ]; then
                    var_name="$var_name${line%"${line#?}"}"
                elif [ $in_subshell -eq 1 ]; then
                    subshell_cmd="$subshell_cmd${line%"${line#?}"}"
                else
                    result="$result${line%"${line#?}"}"
                fi
                line="${line#?}"
                ;;
        esac
    done
    
    printf '%s\n' "$result"
}

process_include() {
    local include_file="$1"
    [ -f "$include_file" ] || { echo "Warning: Include file '$include_file' not found" >&2; return 1; }
    process_template "$include_file"
}

process_conditional() {
    local condition="$1"
    eval "$condition"
}

process_line() {
    local line="$1"
    
    # Handle includes
    if starts_with "$line" "$INCLUDE_PREFIX "; then
        local include_file
        include_file=$(trim "${line#$INCLUDE_PREFIX }")
        process_include "$include_file"
        return
    fi

    # Handle conditionals
    if starts_with "$line" "$IF_PREFIX "; then
        local condition
        condition="${line#$IF_PREFIX }"
        if process_conditional "$condition"; then
            continue_processing=true
            in_else_block=false
        else
            continue_processing=false
            in_else_block=false
        fi
        return
    fi

    if [ "$line" = "$ELSE_TOKEN" ]; then
        if [ "$continue_processing" = "true" ]; then
            continue_processing=false
            in_else_block=true
        else
            continue_processing=true
            in_else_block=true
        fi
        return
    fi

    if [ "$line" = "$ENDIF_TOKEN" ]; then
        continue_processing=true
        in_else_block=false
        return
    fi

    # Process normal line
    [ "$continue_processing" = "false" ] || expand_vars "$line"
}

process_template() {
    local file="$1"
    local IFS=''
    
    while read -r line || [ -n "$line" ]; do
        process_line "$line"
    done < "$file"
}

main() {
    # Argument validation
    [ $# -ge 1 ] || show_usage
    local template_file="$1"
    shift
    [ -f "$template_file" ] || die "Template file not found: $template_file"

    # Initialize state
    continue_processing=true
    in_else_block=false

    # Process command line variables
    process_variables "$@"

    # Process the template
    process_template "$template_file"
}

main "$@" 