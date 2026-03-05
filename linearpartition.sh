#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: linearpartition.sh [options] < input.fa

This is a Bash wrapper for bin/linearpartition_c and bin/linearpartition_v.
Input is read from STDIN (same as the original Python wrapper).

Options (matching the Python gflags wrapper):
  -b, --beamsize INT            set beam size (default: 100)
  -V, --Vienna                  use Vienna parameters (default: off)
      --sharpturn               enable sharp turn in prediction
      --verbose                 print beamsize / energy info / runtime info
  -o, --output FILE             output base pairing probability matrix to FILE (no overwrite)
  -r, --rewrite FILE            output base pairing probability matrix to FILE (overwrite)
      --prefix STR              output bpp matrices to file(s) with prefix STR (wrapper adds '_' automatically)
  -p, --part                    only do partition function calculation (unless --mea or --threshknot)
  -c, --cutoff FLOAT            only output base pair prob >= cutoff (0..1)
  -f, --dumpforest FILE         dump forest to FILE
  -M, --mea                     get MEA structure
  -g, --gamma FLOAT             set MEA gamma (default: 3.0)
      --mea_prefix STR          output MEA structure(s) with prefix STR (wrapper adds '_' automatically)
      --bpseq                   output MEA structure(s) in bpseq format
  -T, --threshknot              get ThreshKnot structure
      --threshold FLOAT         set ThreshKnot threshold (default: 0.3)
      --threshknot_prefix STR   output ThreshKnot structure(s) with prefix STR (wrapper adds '_' automatically)
      --shape FILE              import SHAPE data for SHAPE guided LinearPartition
      --fasta                   input is in fasta format
  -d, --dangles {0|2}           dangling end energies (default: 2)
  -y, --evaly STR               batch eval sequences against structure for p(y|x) (forces Vienna mode)
  -h, --help                    show this help

Examples:
  cat seq.fa | ./linearpartition.sh -b 200 -V --verbose
  cat seq.fa | ./linearpartition.sh -o out.bpp
  cat seq.fa | ./linearpartition.sh -r out.bpp --cutoff 0.2
EOF
}

# ---- defaults (match Python wrapper) ----
beamsize="100"
vienna=0
sharpturn=0
verbose=0
output=""
prefix=""
part=0
rewrite=""
cutoff="None"         # Python default: None -> str(None) == "None"
dumpforest=""
mea=0
gamma="3.0"
mea_prefix=""
bpseq=0
threshknot=0
threshold="0.3"
threshknot_prefix=""
shape=""
fasta=0
dangles="2"
evaly=""

# ---- argument parsing (no external getopt dependency) ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--beamsize)
      [[ $# -ge 2 ]] || { echo "ERROR: $1 requires a value" >&2; usage >&2; exit 2; }
      beamsize="$2"; shift 2;;
    --beamsize=*)
      beamsize="${1#*=}"; shift;;

    -V|--Vienna|--vienna)
      vienna=1; shift;;

    --sharpturn)
      sharpturn=1; shift;;

    --verbose)
      verbose=1; shift;;

    -o|--output)
      [[ $# -ge 2 ]] || { echo "ERROR: $1 requires a value" >&2; usage >&2; exit 2; }
      output="$2"; shift 2;;
    --output=*)
      output="${1#*=}"; shift;;

    --prefix)
      [[ $# -ge 2 ]] || { echo "ERROR: $1 requires a value" >&2; usage >&2; exit 2; }
      prefix="$2"; shift 2;;
    --prefix=*)
      prefix="${1#*=}"; shift;;

    -p|--part)
      part=1; shift;;

    -r|--rewrite)
      [[ $# -ge 2 ]] || { echo "ERROR: $1 requires a value" >&2; usage >&2; exit 2; }
      rewrite="$2"; shift 2;;
    --rewrite=*)
      rewrite="${1#*=}"; shift;;

    -c|--cutoff)
      [[ $# -ge 2 ]] || { echo "ERROR: $1 requires a value" >&2; usage >&2; exit 2; }
      cutoff="$2"; shift 2;;
    --cutoff=*)
      cutoff="${1#*=}"; shift;;

    -f|--dumpforest)
      [[ $# -ge 2 ]] || { echo "ERROR: $1 requires a value" >&2; usage >&2; exit 2; }
      dumpforest="$2"; shift 2;;
    --dumpforest=*)
      dumpforest="${1#*=}"; shift;;

    -M|--mea)
      mea=1; shift;;

    -g|--gamma)
      [[ $# -ge 2 ]] || { echo "ERROR: $1 requires a value" >&2; usage >&2; exit 2; }
      gamma="$2"; shift 2;;
    --gamma=*)
      gamma="${1#*=}"; shift;;

    --mea_prefix)
      [[ $# -ge 2 ]] || { echo "ERROR: $1 requires a value" >&2; usage >&2; exit 2; }
      mea_prefix="$2"; shift 2;;
    --mea_prefix=*)
      mea_prefix="${1#*=}"; shift;;

    --bpseq)
      bpseq=1; shift;;

    -T|--threshknot)
      threshknot=1; shift;;

    --threshold)
      [[ $# -ge 2 ]] || { echo "ERROR: $1 requires a value" >&2; usage >&2; exit 2; }
      threshold="$2"; shift 2;;
    --threshold=*)
      threshold="${1#*=}"; shift;;

    --threshknot_prefix)
      [[ $# -ge 2 ]] || { echo "ERROR: $1 requires a value" >&2; usage >&2; exit 2; }
      threshknot_prefix="$2"; shift 2;;
    --threshknot_prefix=*)
      threshknot_prefix="${1#*=}"; shift;;

    --shape)
      [[ $# -ge 2 ]] || { echo "ERROR: $1 requires a value" >&2; usage >&2; exit 2; }
      shape="$2"; shift 2;;
    --shape=*)
      shape="${1#*=}"; shift;;

    --fasta)
      fasta=1; shift;;

    -d|--dangles)
      [[ $# -ge 2 ]] || { echo "ERROR: $1 requires a value" >&2; usage >&2; exit 2; }
      dangles="$2"; shift 2;;
    --dangles=*)
      dangles="${1#*=}"; shift;;

    -y|--evaly)
      [[ $# -ge 2 ]] || { echo "ERROR: $1 requires a value" >&2; usage >&2; exit 2; }
      evaly="$2"; shift 2;;
    --evaly=*)
      evaly="${1#*=}"; shift;;

    -h|--help)
      usage; exit 0;;

    --)
      shift; break;;

    *)
      echo "ERROR: Unknown option: $1" >&2
      usage >&2
      exit 2;;
  esac
done

# No positional args expected; input comes from STDIN like the Python version
if [[ $# -gt 0 ]]; then
  echo "ERROR: Unexpected positional arguments: $*" >&2
  usage >&2
  exit 2
fi

# ---- replicate Python wrapper warnings / checks ----

if [[ $part -eq 1 && ( -n "$output" || -n "$prefix" ) ]]; then
  echo -e "\nWARNING: -p mode has no output for base pairing probability matrix!\n" >&2
fi

if [[ -n "$output" && -n "$rewrite" ]]; then
  echo -e "WARNING: choose either -o mode or -r mode!\n" >&2
  echo -e "Exit!\n" >&2
  exit 1
fi

if [[ ( -n "$output" || -n "$rewrite" ) && -n "$prefix" ]]; then
  echo -e "WARNING: choose either -o/-r mode or --prefix mode!\n" >&2
  echo -e "Exit!\n" >&2
  exit 1
fi

bpp_file="$output"
if [[ -n "$output" ]]; then
  if [[ -e "$output" ]]; then
    echo -e "WARNING: this file name has already be taken. Choose another name or use -r mode.\n" >&2
    echo -e "Exit!\n" >&2
    exit 1
  fi
fi

if [[ -n "$rewrite" ]]; then
  bpp_file="$rewrite"
  [[ -e "$bpp_file" ]] && rm -f -- "$bpp_file"
fi

# cutoff validation only if user provided -c/--cutoff (i.e., not "None")
if [[ "$cutoff" != "None" ]]; then
  # validate numeric range 0..1 (float)
  if ! awk -v c="$cutoff" 'BEGIN{exit(!(c+0==c && c>=0.0 && c<=1.0))}'; then
    echo -e "WARNING: base pair probability cutoff should be between 0.0 and 1.0\n" >&2
    echo -e "Exit!\n" >&2
    exit 1
  fi
fi

# evaly forces Vienna mode (as in Python wrapper)
if [[ -n "$evaly" ]]; then
  vienna=1
fi

# ---- derived values (match Python wrapper) ----
bpp_prefix=""
if [[ -n "$prefix" ]]; then
  bpp_prefix="${prefix}_"
fi

MEA_prefix=""
if [[ -n "$mea_prefix" ]]; then
  MEA_prefix="${mea_prefix}_"
fi

ThreshKnot_prefix=""
if [[ -n "$threshknot_prefix" ]]; then
  ThreshKnot_prefix="${threshknot_prefix}_"
fi

# pf_only is 1 only if -p and not (mea or threshknot)
pf_only=0
if [[ $part -eq 1 && $mea -eq 0 && $threshknot -eq 0 ]]; then
  pf_only=1
fi

# Convert booleans to the exact '1'/'0' strings expected by the binary
is_sharpturn="$sharpturn"
is_verbose="$verbose"
use_vienna="$vienna"
mea_flag="$mea"
tk_flag="$threshknot"
MEA_bpseq="$bpseq"
is_fasta="$fasta"

# ---- locate the binary relative to the *real* script location (resolves symlinks) ----
resolve_self() {
  local src="${BASH_SOURCE[0]}"
  while [[ -L "$src" ]]; do
    local dir
    dir="$(cd -P -- "$(dirname -- "$src")" && pwd)"
    local link
    link="$(readlink -- "$src")"
    # If the symlink is relative, resolve it relative to the symlink's directory
    if [[ "$link" != /* ]]; then
      src="$dir/$link"
    else
      src="$link"
    fi
  done
  cd -P -- "$(dirname -- "$src")" && pwd
}

script_dir="$(resolve_self)"
if [[ "$use_vienna" -eq 1 ]]; then
  exe="$script_dir/linearpartition_v"
else
  exe="$script_dir/linearpartition_c"
fi

if [[ ! -x "$exe" ]]; then
  echo "ERROR: Expected executable not found or not executable: $exe" >&2
  exit 127
fi

# ---- call underlying tool (argument order must match Python wrapper) ----
exec "$exe" \
  "$beamsize" \
  "$is_sharpturn" \
  "$is_verbose" \
  "$bpp_file" \
  "$bpp_prefix" \
  "$pf_only" \
  "$cutoff" \
  "$dumpforest" \
  "$mea_flag" \
  "$gamma" \
  "$tk_flag" \
  "$threshold" \
  "$ThreshKnot_prefix" \
  "$MEA_prefix" \
  "$MEA_bpseq" \
  "$shape" \
  "$is_fasta" \
  "$dangles" \
  "$evaly"