#!/bin/sh

# Run as: extras/grade.sh submissions/* 1>grade.sh.log 2>grades.txt

set -euo pipefail

testcases=$(echo $(dirname $0)/examples/dfs-testcases/testcase0{1..3})
process_output="$(dirname $0)/process_output.py"

do_clean_exes() {
  dir=$1
  find "${dir}" -name '*.o' -type f -delete
  find "${dir}" -name 'dfs03' -type f -delete
}

do_clean() {
  dir=$1
  echo "+ cleaning ${dir}"
  do_clean_exes "${dir}"
  rm -f ${dir}/*.log
}

do_make() {
  dir=$1
  echo "+ making ${dir}"
  if ! make -C "${dir}" -k -j 1 &> "${dir}/make.log"; then
    echo "- failed to make ${dir}"
    return 1
  fi
  test_files="intVec.o dfs03.o dfs03"
  for test_file in ${test_files}; do
    if ! find "${dir}" -name "${test_file}" -type f &>/dev/null; then
      echo "- failed to find ${test_file} in ${dir}"
      return 1
    fi
  done
}

do_test_run() {
  dir=$1
  testcase_name=$(basename $2)
  testcase="$2.txt"
  echo "+ running test ${testcase_name} on ${dir}"
  cp "${testcase}" "${dir}"
  if ! "${dir}/dfs03" "${testcase}" &> "${dir}/${testcase_name}.out"; then
    echo "- failed to run test ${testcase_name} on ${dir}"
    return 1
  fi
}

do_test_runs() {
  dir=$1
  echo "+ running tests on ${dir}"
  for testcase in ${testcases}; do
    if ! do_test_run "${dir}" "${testcase}"; then
      echo "- failed to run tests on ${dir}"
      return 1
    fi
  done
}

grade_test_run() {
  dir=$1
  studentid=$(basename $1)
  testcase_name=$(basename $2)
  testcase="$2.txt"
  testcase_outputs_dir="$2/"
  ${process_output} "${dir}/${testcase_name}.out" ${testcase_outputs_dir}/* > "${dir}/${testcase_name}.grade"
  grade_str=$(printf "%s %s %s\n" "${studentid}" "${testcase_name}" $(cat "${dir}/${testcase_name}.grade"))
  echo "* ${grade_str}"
  echo "${grade_str}" 1>&2
}

grade_test_runs() {
  dir=$1
  echo "+ grading tests on ${dir}"
  for testcase in ${testcases}; do
    grade_test_run "${dir}" "${testcase}"
  done
}

do_dir() {
  dir=$1
  failed=0
  grader_log_file="${dir}/grader.log"
  echo "+ doing ${dir}" | tee "${grader_log_file}"
  do_clean "${dir}" 2>&1 | tee -a "${grader_log_file}"
  if ! (do_make "${dir}" 2>&1 | tee -a "${grader_log_file}"); then
    failed=1
  fi
  if [[ "${failed}" = 0 ]]; then
    if ! (do_test_runs "${dir}" 2>&1 | tee -a "${grader_log_file}"); then
      failed=1
    fi
  fi
  grade_test_runs "${dir}" | tee -a "${grader_log_file}"
  do_clean_exes "${dir}"
  echo "+ finished ${dir}" | tee "${grader_log_file}"
}

# Grade all
for dir in $@; do
  do_dir "${dir}" || true
done
