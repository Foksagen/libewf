#!/usr/bin/env bash
# Info tool testing script
#
# Version: 20230410

EXIT_SUCCESS=0;
EXIT_FAILURE=1;
EXIT_IGNORE=77;

PROFILES=("ewfinfo");
OPTIONS_PER_PROFILE=("");
OPTION_SETS="";

INPUT_GLOB="*.[ELels]*01";

if test -n "${SKIP_TOOLS_TESTS}" || test -n "${SKIP_TOOLS_END_TO_END_TESTS}";
then
	exit ${EXIT_IGNORE};
fi

TEST_EXECUTABLE="../ewftools/ewfinfo";

if ! test -x "${TEST_EXECUTABLE}";
then
	TEST_EXECUTABLE="../ewftools/ewfinfo.exe";
fi

if ! test -x "${TEST_EXECUTABLE}";
then
	echo "Missing test executable: ${TEST_EXECUTABLE}";

	exit ${EXIT_FAILURE};
fi

TEST_RUNNER="tests/test_runner.sh";

if ! test -f "${TEST_RUNNER}";
then
	TEST_RUNNER="./test_runner.sh";
fi

if ! test -f "${TEST_RUNNER}";
then
	echo "Missing test runner: ${TEST_RUNNER}";

	exit ${EXIT_FAILURE};
fi

source ${TEST_RUNNER};

if ! test -d "input";
then
	echo "Test input directory not found.";

	exit ${EXIT_IGNORE};
fi
RESULT=`ls input/* | tr ' ' '\n' | wc -l`;

if test ${RESULT} -eq ${EXIT_SUCCESS};
then
	echo "No files or directories found in the test input directory";

	exit ${EXIT_IGNORE};
fi

for PROFILE_INDEX in ${!PROFILES[*]};
do
	TEST_PROFILE=${PROFILES[${PROFILE_INDEX}]};

	TEST_PROFILE_DIRECTORY=$(get_test_profile_directory "input" "${TEST_PROFILE}");

	IGNORE_LIST=$(read_ignore_list "${TEST_PROFILE_DIRECTORY}");

	IFS=" " read -a OPTIONS <<< ${OPTIONS_PER_PROFILE[${PROFILE_INDEX}]};

	RESULT=${EXIT_SUCCESS};

	for TEST_SET_INPUT_DIRECTORY in input/*;
	do
		if ! test -d "${TEST_SET_INPUT_DIRECTORY}";
		then
			continue;
		fi
		TEST_SET=`basename ${TEST_SET_INPUT_DIRECTORY}`;

		if check_for_test_set_in_ignore_list "${TEST_SET}" "${IGNORE_LIST}";
		then
			continue;
		fi
		TEST_SET_DIRECTORY=$(get_test_set_directory "${TEST_PROFILE_DIRECTORY}" "${TEST_SET_INPUT_DIRECTORY}");

		run_test_on_test_set_with_options "${TEST_SET_DIRECTORY}" "ewfinfo" "with_stdout_reference" "${OPTION_SETS}" "${TEST_EXECUTABLE}" "${OPTIONS[@]}";
		RESULT=$?;

		# Ignore failures due to corrupted data.
		if test "${TEST_SET}" = "corrupted";
		then
			RESULT=${EXIT_SUCCESS};
		fi
		if test ${RESULT} -ne ${EXIT_SUCCESS};
		then
			break;
		fi
	done
done

exit ${RESULT};

