{ mkDerivation, aeson, attoparsec, base, bytestring, email-validate
, exceptions, fetchgit, filepath, http-client, http-client-tls
, http-types, lib, tagsoup, text, time, transformers
}:
mkDerivation {
  pname = "hailgun";
  version = "0.5.1";
  src = fetchgit {
    url = "https://github.com/MercuryTechnologies/hailgun";
    sha256 = "0hwapi73di9qnggy7zjmn8bnslxajbwisrnf5ismz9rbjg5q9g0g";
    rev = "cbf00c798dd6cceebae872cf8eeda0109900d2c4";
    fetchSubmodules = true;
  };
  libraryHaskellDepends = [
    aeson attoparsec base bytestring email-validate exceptions filepath
    http-client http-client-tls http-types tagsoup text time
    transformers
  ];
  homepage = "https://bitbucket.org/echo_rm/hailgun";
  description = "Mailgun REST api interface for Haskell";
  license = lib.licenses.mit;
}
