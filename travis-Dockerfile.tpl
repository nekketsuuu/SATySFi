# This Dockerfile is automatically generated from a simple template file.

FROM ocaml/opam:%distro%_ocaml-%ocaml_version%

WORKDIR build
ADD . .
# enable --yes option for opam commands (see `opam --help`)
ENV OPAMYES "true"
# enable/disable tests (see `opam install --help`)
ENV OPAMBUILDTEST %opambuildtest%
# install
RUN opam update \
 && opam pin add --no-action %package% . \
 && opam depext --update %package% \
 && opam install --deps-only %package%
CMD opam install %package%
