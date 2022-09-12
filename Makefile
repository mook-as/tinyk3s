NERDCTL_VERSION = 0.23.0
AGENT_VERSION = 0.1.2
CRI_DOCKERD_VERSION = 0.2.3
CRI_DOCKERD_ORG=Mirantis

distro.tar:

# Make expansion to add --build-arg for a variable if it's set.
arg = $(if $($(1)),--build-arg "$(1)=$($(1))")

args = BUILD_ID VERSION_ID NERDCTL_VERSION AGENT_VERSION CRI_DOCKERD_VERSION

nerdctl-$(NERDCTL_VERSION).tgz:
	wget -O "$@" \
		"https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-full-${NERDCTL_VERSION}-linux-amd64.tar.gz"

rancher-desktop-guestagent-$(AGENT_VERSION):
	wget -O "$@" \
		"https://github.com/rancher-sandbox/rancher-desktop-agent/releases/download/v${AGENT_VERSION}/rancher-desktop-guestagent"

cri-dockerd-$(CRI_DOCKERD_VERSION).tgz:
	wget -O "$@" \
		"https://github.com/$(CRI_DOCKERD_ORG)/cri-dockerd/releases/download/v${CRI_DOCKERD_VERSION}/cri-dockerd-${CRI_DOCKERD_VERSION}.amd64.tgz"
	wget -O "cri-dockerd-$(CRI_DOCKERD_VERSION).LICENSE" \
		"https://raw.githubusercontent.com/$(CRI_DOCKERD_ORG)/cri-dockerd/v$(CRI_DOCKERD_VERSION)/LICENSE"

image-id: Dockerfile $(wildcard files/*) nerdctl-$(NERDCTL_VERSION).tgz rancher-desktop-guestagent-$(AGENT_VERSION) cri-dockerd-$(CRI_DOCKERD_VERSION).tgz
	docker build $(foreach a,$(args),$(call arg,$(a))) --iidfile "$@" --file "$<" .

container-id: image-id
	docker create --cidfile "$@" "$(shell cat "$<")" -- /bin/true

distro.tar: container-id
	docker export --output "$@" "$(shell cat "$<")"
	docker rm -f "$(shell cat "$<")"

.INTERMEDIATE: image-id container-id
