#!/usr/bin/env bash

function get_bash_startup_file() {
  for file in "${HOME}/.bashrc" \
              "${HOME}/.bash_profile"
  do
    if [[ -f "${file}" ]]; then
      echo "${file}"
      return
    fi
  done
  touch "${HOME}/.bashrc"
  ln -s ".bashrc" "${HOME}/.bash_profile"
  echo "${HOME}/.bashrc"
}

function normalize_path() {
  # Removes unnecessary slashes and resolves '.' and '..' to return the shortest
  # path equivalent to the one given as input. The path does not have to exist.
  local path nodes=() n abs IFS="/" # split path on "/"
  _set_path_from_args_or_stdin "$@"
  _set_nodes_array "${path}"
  n=${#nodes[@]}
  [[ "${path:0:1}" == "/" ]] && abs="/" || abs="" # relative or absolute path?
  local i node nodes_out=() n_out=0
  for ((i=0; i < $n ; i++)); do
    node="${nodes[$i]}"
    if [[ "${node}" == "" ]] || [[ "${node}" == "." ]]; then
      continue # 'foo//bar' or 'foo/./bar' gives 'foo/bar'
    elif [[ "${node}" == ".." ]]; then
      if (($n_out > 0)) && [[ "${nodes_out[$n_out-1]}" != ".." ]]; then
        ((n_out--))
        unset "nodes_out[$n_out]"
        continue # 'foo/../..' gives '..'
      elif [[ "${abs}" ]]; then
        continue # '/..' gives '/'
      fi
    fi
    nodes_out[$n_out]="${node}"
    ((n_out++))
  done
  if (($n_out > 0)); then
    echo "${abs}${nodes_out[*]}" # ${array[*]}: array elements separated by IFS
  elif [[ "${abs}" ]]; then
    echo "/"
  else
    echo "."
  fi
}

function _normalize_path() {
  local normpath
  _set_normpath "$1"
  echo "${normpath}"
}

function _set_normpath() {
  # Removes unnecessary slashes and resolves '.' and '..' to return the shortest
  # path equivalent to the one given as input. The path does not have to exist.
  local path basename dirname abs skip=0
  _set_path_from_args_or_stdin "$@"
  [[ "${path:0:1}" == "/" ]] && abs="/" || abs="" # relative or absolute path?
  while [[ ! "${path}" =~ ^\.?/*$ ]]; do
    _set_basename "${path}"
    _set_dirname "${path}"
    if [[ "${basename}" == "." ]]; then
      : # ignore node
    elif [[ "${basename}" == ".."  ]]; then
      ((skip++)) # skip next node that isn't '.' or '..' or already skipped
    elif ((skip > 0)); then
      ((skip--)) # skipping this node due to prior '..'
    else
      normpath="${basename}/${normpath}" # add node to normpath
    fi
    path="${dirname}" # move to next node
  done
  if [[ ! "${abs}" ]]; then
    while ((skip > 0)); do
      normpath="../${normpath}"
      ((skip--))
    done
  fi
  if [[ "${normpath}" ]]; then
    normpath="${abs}${normpath%/}" # strip trailing slash
  elif [[ "${abs}" ]]; then
    normpath="/"
  else
    normpath="."
  fi
}


function absolute_path() {
  # Appends $PWD to $path if $path is relative (does not start with '/'). $path
  # does not have to exist. Output is not normalized or canonicalized.
  local path && _set_path_from_args_or_stdin "$@"
  if [[ "${path:0:1}" == "/" ]]; then
    echo "${path}"
  else
    echo "${PWD}/${path}"
  fi
}

function canonical_path() {
  # Prints physical path without symbolic links. ${path} must exist on system.
  local path realpath dirname && _set_path_from_args_or_stdin "$@"

  while [[ -L "${path}" ]]; do
    realpath="$(readlink ${path})"
    if [[ "${realpath:0:1}" == "/" ]]; then
      path="${realpath}"
    else
      _set_dirname "${path}"
      path="${dirname}/${realpath}"
    fi
  done
  if [[ ! -e "${path}" ]]; then
    echo "${FUNCNAME[0]}: error: file not found: ${path}" >&2
    return 1
  fi
  if [[ -d "${path}" ]]; then
    realpath="$(cd "${path}" && pwd -P && echo "x")"
    realpath="${realpath%$'\nx'}" # strip 'x' and single \n
  else
    local basename dirname
    _set_basename "${path}"
    _set_dirname "${path}"
    # Problem: trailing '\n' chars will be stripped during command substitution.
    # Solution: append 'x' and stip later. Also strip single '\n' if needed.
    realpath="$(cd "${dirname}" && pwd -P && echo "x")"
    if [[ "${basename}" == "." ]]; then
      realpath="${realpath%$'\nx'}" # strip 'x' and single \n
    elif [[ "${basename}" == ".." ]]; then
      realpath="${realpath%/*}" # strip final slash and everything after
    else
      realpath="${realpath%$'\nx'}/${basename}" # strip '\nx' and add $basename
    fi
  fi
  echo "${realpath}"
}

function filename() {
  local path="$1" && echo "path=${path}"
  local basename="${path##*/}" && echo "basename=${basename}"
  local dirname="${path/%${basename}/}" && echo "dirname=${dirname}"
}

function get_path_relative_to_path() {
  local path_to_find="$(absolute_path "$1" | normalize_path)"
  local relative_to="$(absolute_path "$2" | normalize_path)"
  if [[ "${path_to_find}" == "${relative_to}" ]]; then
    echo "."
  elif [[ "${path_to_find}" == "${relative_to}"* ]]; then
    echo "${path_to_find#*${relative_to}/}"
  elif [[ "${relative_to}" == "${path_to_find}"* ]]; then
    echo "../${path_to_find}"
  else
    echo "${path_to_find}"
  fi
}

function repeat() {
  local n=$((-$1)) q && shift
  ((n > 0)) || return 1
  "$@" >&2
  for ((q=1; q < n; q++)); do
    "$@" &>/dev/null
  done
}

function compare() {
  local cmd="$1"
  shift
  printf "%s: " "${cmd}" && "${cmd}" "$@"
  printf "%s: " "_${cmd}" && "_${cmd}" "$@"
}

function compare_time() {
  local repeats="$1" cmds=() i=0
  while shift ; [[ "$1" != "--" ]]; do
    ((i++))
    cmds[i]="$1"
  done
  shift
  for cmd in "${cmds[@]}"; do
    printf "%s: " "${cmd}" && time repeat $repeats "${cmd}" "$@" && echo
  done
}

function _set_path_from_args_or_stdin() {
  # set $path variable in caller shell with input from $1 or STDIN
  # Usage: local path && _set_path_from_args_or_stdin "$@"
  if (($# > 0)); then
    path="$1"
  else
    read -d '' -r path # path from STDIN (path may contain newlines)
    path="${path%$'\n'}" # strip extra newline added by read -d ''
  fi
}

function _set_nodes_array() {
  # set $nodes array in caller shell with result of splitting $1 on "/"
  # Usage: local nodes=() && _set_nodes_array "${path}"
  local length=${#1} IFS="/" # split path on "/"
  # read $path into array. Only read $lenght chars to avoid extra '\n' chars.
  ((length == 0)) || read -d '' -n $length -r -a nodes <<<"$1"
}

function _basename() {
  local basename
  _set_basename "$1"
  echo "${basename}"
}

function _dirname() {
  local dirname
  _set_dirname "$1"
  echo "${dirname}"
}

function _set_basename() {
  # set $basename variable in caller shell with basename of $1. Avoids subshell.
  # Usage: local basename && _set_basename "${path}"
  local path="$1"
  if [[ "${path}" =~ ^/+$ ]]; then
    basename="/" # path consists only of slashes
    return # '/////' gives '/'
  fi
  while [[ "${path}" == *"/" ]]; do
    path="${path%/}" # strip trailing slash(es): 'foo/bar//' goes to 'foo/bar'
  done
  # return everything after final slash, or everything if there are no slashes
  basename="${path##*/}" # 'foo/bar' or 'bar' gives 'bar'
}

function _set_dirname() {
  # set $dirname variable in caller function dirname of $1. Avoids subshell.
  # Usage: local dirname && _set_dirname "${path}"
  local path="$1"
  if [[ "${path}" =~ ^/*[^/]*/*$ ]]; then # path only has one node: //foo///
    if [[ "${path:0:1}" == / ]]; then
      dirname="/" # '//foo///', '//foo' or '//' gives '/' (shortest absolute path)
    else
      dirname="." # 'foo///', 'foo' or '' gives '.' (shortest relative path)
    fi
    return
  fi
  while [[ "${path}" == */ ]]; do # strip any trailing slash(es)
    path="${path%/}" # 'foo///bar///' goes to 'foo///bar'
  done
  # only keep characters before the final slash, or everything if no slashes
  path="${path%/*}" # 'foo///bar' goes to 'foo//', 'foo' goes to 'foo'
  while [[ "${path}" == */ ]]; do
    path="${path%/}" # strip trailing slash(es):  'foo//' goes to 'foo'
  done
  dirname="${path}"
}

function ensure_file_contains_line() {
  local file="$1"
  local line="$2"
  if ! grep "${line}" "${file}" &>/dev/null; then
    echo "${line}" >> "${file}"
  fi
}
