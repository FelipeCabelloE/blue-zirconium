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

vm:
    sudo podman run --rm -it \
      -v ./output:/output \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      quay.io/centos-bootc/bootc-image-builder:latest \
      --type qcow2 \
      --local \
      {{ registry }}/{{ image }}:{{ tag }}

test: vm
    qemu-system-x86_64 -m 4096 -enable-kvm \
      -drive file=./output/qcow2/disk.qcow2
