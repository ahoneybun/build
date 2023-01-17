function cli_patch_kernel_pre_run() {
	declare -g ARMBIAN_COMMAND_REQUIRE_BASIC_DEPS="yes" # Require prepare_host_basic to run before the command.

	# "gimme root on a Linux machine"
	cli_standard_relaunch_docker_or_sudo
}

function cli_patch_kernel_run() {
	display_alert "Patching kernel" "$BRANCH" "info"
	declare -g SYNC_CLOCK=no      # don't waste time syncing the clock
	declare -g JUST_KERNEL=yes    # only for kernel.
	declare -g KERNEL_ONLY=yes    # don't build images
	declare -g PATCHES_TO_GIT=yes # commit to git.
	declare -g PATCH_ONLY=yes     # stop after patching.
	declare -g DEBUG_PATCHING=yes # debug patching.
	declare -g GIT_ARCHEOLOGY=yes # do archeology
	#declare -g REWRITE_PATCHES=yes # rewrite the patches after git commiting. Very cheap compared to the rest.
	declare -g KERNEL_CONFIGURE=no # no menuconfig
	declare -g RELEASE=jammy       # or whatever, not relevant, just fool the configuration
	declare -g SHOW_LOG=yes        # show the log
	prepare_and_config_main_build_single

	declare ymd vendor_lc target_repo_url summary_url
	ymd="$(date +%Y%m%d)"
	# lowercase ${VENDOR} and replace spaces with underscores
	vendor_lc="$(tr '[:upper:]' '[:lower:]' <<< "${VENDOR}" | tr ' ' '_')-next"
	target_branch="${vendor_lc}-${LINUXFAMILY}-${KERNEL_MAJOR_MINOR}-${ymd}${PUSH_BRANCH_POSTFIX:-""}"
	target_repo_url="git@github.com:${PUSH_TO_REPO:-"${PUSH_TO_USER:-"rpardini"}/${PUSH_TO_REPO:-"linux"}"}.git"
	summary_url="https://${PUSH_TO_USER:-"rpardini"}.github.io/${PUSH_TO_REPO:-"linux"}/${target_branch}.html"

	declare -a push_command
	push_command=(git -C "${SRC}/cache/git-bare/kernel" push "--force" "--verbose"
		"${target_repo_url}"
		"kernel-${LINUXFAMILY}-${KERNEL_MAJOR_MINOR}:${target_branch}")

	# Prepare the host and build kernel instead of main_default_build_single
	prepare_host # This handles its own logging sections, and is possibly interactive.
	compile_kernel # This handles its own logging sections.

	display_alert "Done patching kernel" "${BRANCH} - ${LINUXFAMILY} - ${KERNEL_MAJOR_MINOR}" "cachehit"

	declare do_push="no"
	if git -C "${SRC}" remote get-url origin &> /dev/null; then
		declare src_origin_url
		src_origin_url="$(git -C "${SRC}" remote get-url origin | xargs echo -n)"

		declare prefix="git@github.com:${PUSH_TO_USER:-"rpardini"}/" # @TODO refactor var
		# if the src_origin_url begins with the prefix
		if [[ "${src_origin_url}" == "${prefix}"* ]]; then
			do_push="yes"
		fi
	fi

	display_alert "Git push command: " "${push_command[*]}" "info"
	if [[ "${do_push}" == "yes" ]]; then
		display_alert "Pushing to ${target_branch}" "${target_repo_url}" "info"
		"${push_command[@]}"
		display_alert "Done pushing to ${target_branch}" "${summary_url}" "info"
	fi

	display_alert "Summary URL (after push & gh-pages deploy): " "${summary_url}" "info"
}