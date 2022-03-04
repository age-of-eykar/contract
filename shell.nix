with import <nixpkgs> { };

stdenv.mkDerivation {
  name = "python-3.7-environment";
  buildInputs = [ python37 ];
}