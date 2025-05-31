#!/usr/bin/env bash
# ------------------------------------------------------------
# quiz.sh  —  Modular interactive shell‑quiz program
# ------------------------------------------------------------
# • Quizzes live in separate files inside ./quizzes/
#   (or a directory set via $QUIZ_DIR).  Each file is a small
#   Bash snippet that defines three variables:
#       quiz_title       - a string
#       quiz_questions   - an array of questions
#       quiz_answers     - an array with the same length
#   Example (save as quizzes/command_line.quiz):
#       quiz_title="Command‑Line Fundamentals"
#       quiz_questions=(
#           "Print the current working directory (command only)"
#           "Hidden files and directories begin with what character"
#       )
#       quiz_answers=( "pwd" "." )
#
# • This version walks **sequentially** through **every** quiz file
#   it finds (sorted by filename).  Before each quiz begins you can:
#       ↵  <Enter>  — start the quiz
#       s          — skip this quiz
#       q          — quit the program entirely
# ------------------------------------------------------------

set -u  # treat unset variables as an error; catch typos

# Location of quiz definition files (override with $QUIZ_DIR)
QUIZ_DIR="${QUIZ_DIR:-$(dirname "$0")/quizzes}"

# ---------- Helper functions ---------------------------------

# Trim leading / trailing whitespace (keeps internal spacing)
trim() {
  local s=$1
  s="${s#"${s%%[![:space:]]*}"}"  # ltrim
  s="${s%"${s##*[![:space:]]}"}"  # rtrim
  printf '%s' "$s"
}

# run_quiz <questions‑nameref> <answers‑nameref> <title>
run_quiz() {
  local -n _qs=$1   # nameref to questions array
  local -n _as=$2   # nameref to answers array
  local _title=$3

  printf '\n=== %s ===\n' "$_title"
  local total=${#_qs[@]}
  local score=0

  for i in "${!_qs[@]}"; do
    printf '\nQuestion %d/%d:\n%s\n' "$((i+1))" "$total" "${_qs[$i]}"
    read -r -p 'Answer: ' user_ans

    local ua lc ca
    ua=$(trim "$user_ans")
    lc="${ua,,}"
    ca="${_as[$i],,}"

    if [[ "$lc" == "$ca" ]]; then
      echo "✅ Correct!"
      ((score++))
    else
      echo "❌ Incorrect.  Correct answer: ${_as[$i]}"
    fi
  done

  printf '\n>>> Score: %d/%d (%.0f%%) <<<\n' "$score" "$total" $(( 100*score/total ))
}

# ---------- Main routine -------------------------------------

if [[ ! -d "$QUIZ_DIR" ]]; then
  echo "Error: quiz directory \"$QUIZ_DIR\" not found." >&2
  exit 1
fi

mapfile -t quiz_files < <(find "$QUIZ_DIR" -type f -name '*.quiz' | sort)
if (( ${#quiz_files[@]} == 0 )); then
  echo "No quiz files (*.quiz) found inside \"$QUIZ_DIR\"." >&2
  exit 1
fi

echo "Found ${#quiz_files[@]} quiz file(s) in '$QUIZ_DIR'."

for quiz_file in "${quiz_files[@]}"; do
  # shellcheck source=/dev/null
  unset -v quiz_title quiz_questions quiz_answers
  source "$quiz_file" || { echo "Failed to source '$quiz_file' – skipping." >&2; continue; }

  if [[ -z ${quiz_title-} || ${#quiz_questions[@]} -eq 0 || \
        ${#quiz_questions[@]} -ne ${#quiz_answers[@]} ]]; then
    echo "Quiz '$quiz_file' is malformed; skipping." >&2
    continue
  fi

  printf '\n--- Ready: %s ---\n' "$quiz_title"
  read -r -p "Press <Enter> to start, 's' to skip, or 'q' to quit: " resp
  case "${resp,,}" in
    q) echo "Goodbye!"; exit 0 ;;
    s) echo "Skipping '$quiz_title'..."; continue ;;
    *) ;; # anything else (including empty) begins the quiz
  esac

  run_quiz quiz_questions quiz_answers "$quiz_title"

done

echo $'\n🎉  You have completed all available quizzes!  🎉'
exit 0

