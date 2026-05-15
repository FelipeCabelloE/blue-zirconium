registry := "ghcr.io/felipecabelloe"
image := "blue-zirconium"
tag := "latest"
_:
    just --list

validate:
    bluebuild validate recipes/recipe.yml

generate:
    bluebuild generate recipes/recipe.yml

build:
    bluebuild build -B podman recipes/recipe.yml

generate-iso:
    bluebuild generate-iso -B podman recipe recipes/recipe.yml

generate-iso-image:
    bluebuild generate-iso -B podman image {{ registry }}/{{ image }}:{{ tag }}

registry-to-vm:
    sudo podman pull {{ registry }}/{{ image }}:{{ tag }}
    sudo podman run --rm -it --privileged \
      -v ./output:/output \
      -v ./cache:/var/cache/image-builder/store \
      -v /var/tmp:/var/tmp \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      ghcr.io/osbuild/image-builder-cli:latest \
      build qcow2 \
      --output-dir /output \
      --bootc-ref {{ registry }}/{{ image }}:{{ tag }} \
      --bootc-default-fs btrfs
    sudo podman rmi {{ registry }}/{{ image }}:{{ tag }}

registry-to-test: registry-to-vm
    qemu-system-x86_64 -m 4096 -enable-kvm \
      -drive file=./output/qcow2/disk.qcow2

local-vm:
    podman save {{ registry }}/{{ image }}:{{ tag }} | sudo podman load
    sudo podman run --rm -it --privileged \
      -v ./output:/output \
      -v ./cache:/var/cache/image-builder/store \
      -v /var/tmp:/var/tmp \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      ghcr.io/osbuild/image-builder-cli:latest \
      build qcow2 \
      --output-dir /output \
      --bootc-ref {{ registry }}/{{ image }}:{{ tag }} \
      --bootc-default-fs btrfs
    sudo podman rmi {{ registry }}/{{ image }}:{{ tag }}

local-test:
    qemu-system-x86_64 -m 4096 -enable-kvm \
      -drive file=./output/qcow2/disk.qcow2
