# Download and install OPAM
brew update > /dev/null
brew install aspcud opam
opam init --compiler="${OCAML_VERSION}"
eval `opam config env`
opam install depext

# Install dependency
opam pin add --no-action "${PACKAGE}.dev" .
opam depext "${PACKAGE}.dev"
opam install --deps-only "${PACKAGE}.dev"
