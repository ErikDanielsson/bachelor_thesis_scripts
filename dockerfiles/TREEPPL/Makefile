username = danielssonerik
reponame = treeppl
miking_dppl_repo = danielssonerik/treeppl-miking-dppl

# Build a docker image of the TreePPL compiler
build:
	docker build  \
		--tag ${USERNAME}/${REPO}:${TAG} \
	 	--build-arg MIKING_DPPL_IMAGE=${MIKING_DPPL_IMAGE} \
		--build-arg TREEPPL_GIT_REMOTE=${REMOTE} \
		--build-arg TREEPPL_GIT_COMMIT=${TREEPPL_REVISION} \
		--no-cache\
		.
	docker push $(USERNAME)/$(REPO):${TAG}

# Install the base version of TreePPL
# Tag it with the commit sha used when building 
treeppl_base_commit = a2259e3
remote = https://github.com/treeppl/treeppl.git
miking_dppl_commit = 70fabcc
miking_dppl_image = ${miking_dppl_repo}:${miking_dppl_commit}

treeppl_base:
	echo $(miking_dppl_image)
	$(MAKE) build \
		USERNAME=$(username) \
		REPO=$(reponame) \
		TAG=$(treeppl_base_commit) \
		MIKING_DPPL_IMAGE=$(miking_dppl_image) \
		TREEPPL_REVISION=$(treeppl_base_commit) \
		REMOTE=$(remote)

custom_drift_kernel_branch = custom-drift-kernels
elegios_remote = https://github.com/elegios/treeppl.git
drift_kernel_miking_dppl_tag = custom-drift-kernels
drift_kernels_dppl_image = ${miking_dppl_repo}:${drift_kernel_miking_dppl_tag}

custom_drift_kernels:
	echo $(miking_dppl_image)
	$(MAKE) build \
		USERNAME=$(username) \
		REPO=$(reponame) \
		TAG=$(custom_drift_kernel_branch) \
		MIKING_DPPL_IMAGE=$(drift_kernels_dppl_image) \
		TREEPPL_REVISION=$(custom_drift_kernel_branch) \
		REMOTE=$(elegios_remote)
