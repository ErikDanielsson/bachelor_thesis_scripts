username = danielssonerik
reponame = treeppl-miking-dppl
miking_repo = danielssonerik/treeppl-miking

# Build a docker image of the Miking DPPL compiler
build:
	docker build  \
		--tag ${USERNAME}/${REPO}:${TAG} \
	 	--build-arg MIKING_IMAGE=${MIKING_IMAGE} \
		--build-arg MIKING_DPPL_GIT_REMOTE=${REMOTE} \
		--build-arg MIKING_DPPL_GIT_COMMIT=${MIKING_DPPL_REVISION} \
		.
	docker push $(USERNAME)/$(REPO):${TAG}

# Make the version of miking compatible with TreePPL
# Tag it with the commit sha used when building miking
miking_dppl_base_commit=70fabcc
remote = https://github.com/treeppl/miking-dppl.git
miking_commit = 24505bd
miking_image = ${miking_repo}:${miking_commit}

treeppl_base:
	$(MAKE) build \
		USERNAME=$(username) \
		REPO=$(reponame) \
		TAG=$(miking_dppl_base_commit) \
		MIKING_IMAGE=$(miking_image) \
		MIKING_DPPL_REVISION=$(miking_dppl_base_commit) \
		REMOTE=$(remote)