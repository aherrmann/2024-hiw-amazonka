{ mkDerivation, aeson, aeson-pretty, base, base16-bytestring
, bytestring, classy-prelude, containers, cryptonite
, data-default-class, deepseq, either, errors, fakepull, fetchgit
, hashable, hspec, hspec-core, hspec-discover, hspec-golden
, http-api-data, http-client, http-client-tls, lib, megaparsec
, mono-traversable, mtl, pretty-simple, QuickCheck
, quickcheck-instances, refined, scientific, servant
, servant-client, servant-client-core, string-conversions
, string-variants, template-haskell, text, th-compat, time
, transformers, unordered-containers, vector
}:
mkDerivation {
  pname = "slack-web";
  version = "0.5.0.1";
  src = fetchgit {
    url = "https://github.com/MercuryTechnologies/slack-web";
    sha256 = "0yrh40s7gj4xj2pf6xg1f00cqqricgks4nkc86p1l31kmsq3gbjh";
    rev = "1ce60453e3ceb36b98bbb2937f70dfbfcc5f8928";
    fetchSubmodules = true;
  };
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    aeson base base16-bytestring bytestring classy-prelude containers
    cryptonite data-default-class deepseq either errors hashable
    http-api-data http-client http-client-tls megaparsec
    mono-traversable mtl refined scientific servant servant-client
    servant-client-core string-conversions string-variants text time
    transformers unordered-containers vector
  ];
  testHaskellDepends = [
    aeson aeson-pretty base bytestring classy-prelude fakepull hspec
    hspec-core hspec-golden mtl pretty-simple QuickCheck
    quickcheck-instances string-conversions string-variants
    template-haskell text th-compat time
  ];
  testToolDepends = [ hspec-discover ];
  homepage = "https://github.com/MercuryTechnologies/slack-web";
  description = "Bindings for the Slack web API";
  license = lib.licenses.mit;
}
