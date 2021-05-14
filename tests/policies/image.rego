package main

has_a_sha256_hash_specified(image_path) {
  regex.match("@sha256:[0-9a-zA-Z]+$", image_path)
}

all_images_have_a_sha256_hash_specified(containers) {
  some i
  container := containers[i]
  not has_a_sha256_hash_specified(container.image)
}

deny[msg] {
  input.kind == "Deployment"
  all_images_have_a_sha256_hash_specified(input.spec.template.spec.containers)

  msg := "Container images must specify a SHA hash"
}