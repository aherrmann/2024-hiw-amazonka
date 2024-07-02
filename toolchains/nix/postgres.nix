{ pkgs, postgresVersion }:

let
  minBound = 12; # inclusive lower
  maxBound = 14; # exclusive upper
  pgValid = pg_version: pg_version >= minBound && pg_version < maxBound;
  postgresVersionStr = builtins.toString postgresVersion;
in if pgValid postgresVersion
   then pkgs."postgresql_${postgresVersionStr}".withPackages(p: [ p.postgis ])
   else throw "Invalid postgres version: ${postgresVersionStr}. Must be greater than or equal to ${builtins.toString minBound} and less than ${builtins.toString maxBound}"
