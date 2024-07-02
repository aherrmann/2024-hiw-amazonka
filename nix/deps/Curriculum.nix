{ mkDerivation, fetchgit, aeson, aeson-casing, base, binary, bytestring
, case-insensitive, containers, cryptonite, esqueleto, exceptions
, extra, hoauth2, http-api-data, http-conduit, http-types, jwt, lib
, memory, persistent-postgresql, resource-pool, text, time
, transformers, uri-bytestring, vector, wai, yesod, yesod-core
}:
mkDerivation {
  pname = "Curriculum";
  version = "1.0.0.0";
  src = fetchgit {
    url = "git@github.com:MercuryTechnologies/curriculum-app.git";
    rev = "6e34e9dc55f2a19d3f4feaf2da5945115ec44932";
    fetchSubmodules = true;
  };
  postUnpack = "sourceRoot+=/backend; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [
    aeson aeson-casing base binary bytestring case-insensitive
    containers cryptonite esqueleto exceptions extra hoauth2
    http-api-data http-conduit http-types jwt memory
    persistent-postgresql resource-pool text time transformers
    uri-bytestring vector wai yesod yesod-core
  ];
  license = lib.licenses.bsd3;
}
