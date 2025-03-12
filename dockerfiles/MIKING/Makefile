username = danielssonerik
reponame = treeppl-miking
baseline_image = mikinglang/baseline:v8-debian12.6-linux-amd64

# Build a docker image of the Miking DPPL compiler
build:
	docker build  \
		--tag ${USERNAME}/${REPO}:${TAG} \
	 	--build-arg BASELINE_IMAGE=${BASELINE_IMAGE} \
		--build-arg MIKING_GIT_REMOTE=${REMOTE} \
		--build-arg MIKING_GIT_COMMIT=${MIKING_REVISION} \
		--no-cache \
		.
	docker push $(USERNAME)/$(REPO):${TAG}

# Make the version of miking compatible with TreePPL
# Tag it with the commit sha used when building miking
miking_base_commit = 24505bd
remote = https://github.com/miking-lang/miking.git
treeppl_base:
	$(MAKE) build \
		USERNAME=$(username) \
		REPO=$(reponame) \
		TAG=$(miking_base_commit) \
		BASELINE_IMAGE=$(baseline_image) \
		MIKING_REVISION=$(miking_base_commit) \
		REMOTE=$(remote)

# Compile miking from the in-progress branch of Viktor Palmkvist
custom_drift_kernel_branch=in-progress
custom_drift_kernel_tag=custom-drift-kernels
elegios_remote=https://github.com/elegios/miking.git
custom_drift_kernels:
	$(MAKE) build \
		USERNAME=$(username) \
		REPO=$(reponame) \
		TAG=$(custom_drift_kernel_tag) \
		BASELINE_IMAGE=$(baseline_image) \
		MIKING_REVISION=$(custom_drift_kernel_branch) \
		REMOTE=$(elegios_remote)