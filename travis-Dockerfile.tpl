# This Dockerfile is automatically generated from a simple template file.

FROM ocaml/opam:%distro%_ocaml-%ocaml_version%

WORKDIR build
ADD . .
ENV OPAMYES "true"                 # enable --yes option for opam commands (see `opam --help`)
ENV OPAMBUILDTEST %opambuildtest%  # enable/disable tests (see `opam install --help`)
RUN opam pin add --no-action %package% . \
 && opam depext --update %package% \
 && opam install --deps-only %package%
CMD opam install %package%
