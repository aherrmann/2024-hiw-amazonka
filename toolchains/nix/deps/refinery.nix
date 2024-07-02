{
  mkDerivation,
  fetchgit,
  base,
  checkers,
  exceptions,
  hspec,
  lib,
  mmorph,
  mtl,
  QuickCheck,
}:
mkDerivation {
  pname = "refinery";
  version = "0.4.0.0";
  src = fetchgit {
    url = "https://github.com/TOTBWF/refinery.git";
    sha256 = "sha256-5S8KjdZ2+LfJW7mNZlX2xUVqY2Ba+LEo2YR4/+oATJk=";
    rev = "e9dbb5fd990ff040c2496c7cf527c45550eb189b";
    fetchSubmodules = true;
  };
  libraryHaskellDepends = [base exceptions mmorph mtl];
  testHaskellDepends = [
    base
    checkers
    exceptions
    hspec
    mmorph
    mtl
    QuickCheck
  ];
  homepage = "https://github.com/totbwf/refinery#readme";
  description = "Toolkit for building proof automation systems";
  license = lib.licenses.bsd3;
}
