#!/usr/bin/env bash
# render.sh — segment pipeline: source → call → join

cc_render() {
  local segments_dir
  segments_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../segments" && pwd)"

  local IFS=','
  local seg_names=($_CFG_SEGMENTS)
  unset IFS

  local outputs=()
  local count=0
  local name seg_file output

  for name in "${seg_names[@]}"; do
    seg_file="${segments_dir}/${name}.sh"
    [ -f "$seg_file" ] || continue

    # Source segment file (defines segment_<name> function)
    . "$seg_file"

    # Call the segment function, capture output
    if output=$(segment_"$name" 2>/dev/null) && [ -n "$output" ]; then
      outputs[$count]="$output"
      count=$((count + 1))
    fi
  done

  # Nothing to render
  [ "$count" -eq 0 ] && return 0

  # Join with themed separator
  local sep
  sep=$(printf '%b%s%b' "${_THEME_SEP}" "${_CFG_SEPARATOR}" "${_CLR_RESET}")

  local i result=""
  for ((i=0; i<count; i++)); do
    [ $i -gt 0 ] && result="${result}${sep}"
    result="${result}${outputs[$i]}"
  done

  printf '%s\n' "$result"
}
