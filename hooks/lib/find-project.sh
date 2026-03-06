# hooks/lib/find-project.sh — sourceable, no shebang
# Shared walk-up functions for locating .pipeline/ and project root.
# All functions respect PIPELINE_TEST_DIR for test-gate.sh compatibility.

# find_pipeline_dir — returns .pipeline dir, falls back to $PWD/.pipeline
find_pipeline_dir() {
  if [ -n "${PIPELINE_TEST_DIR:-}" ]; then
    echo "${PIPELINE_TEST_DIR}/.pipeline"
    return 0
  fi
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.pipeline" ]; then
      echo "$dir/.pipeline"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  echo "$PWD/.pipeline"
}

# find_pipeline_dir_strict — returns .pipeline dir or returns 1
find_pipeline_dir_strict() {
  if [ -n "${PIPELINE_TEST_DIR:-}" ]; then
    echo "${PIPELINE_TEST_DIR}/.pipeline"
    return 0
  fi
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.pipeline" ]; then
      echo "$dir/.pipeline"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

# find_project_root — returns parent of .pipeline or returns 1
find_project_root() {
  if [ -n "${PIPELINE_TEST_DIR:-}" ]; then
    echo "${PIPELINE_TEST_DIR}"
    return 0
  fi
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.pipeline" ]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

# find_file_up <name> — walks up to find a file by name, returns path or 1
find_file_up() {
  local name="$1"
  if [ -n "${PIPELINE_TEST_DIR:-}" ]; then
    if [ -f "${PIPELINE_TEST_DIR}/${name}" ]; then
      echo "${PIPELINE_TEST_DIR}/${name}"
      return 0
    fi
    return 1
  fi
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/$name" ]; then
      echo "$dir/$name"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}
