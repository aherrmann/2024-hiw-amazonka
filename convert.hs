#!/usr/bin/env nix-shell
#! nix-shell -i runghc -p "haskell.packages.ghc982.ghcWithPackages (ps: with ps; [cabal-install-parsers pathwalk pretty-show])"
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedRecordUpdate #-}
{-# LANGUAGE PackageImports #-}
{-# LANGUAGE PolyKinds #-}

import Cabal.Package (readPackage)
import Data.Foldable
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import System.Directory.PathWalk
import System.FilePath
import Text.Show.Pretty (pPrint)
import "Cabal-syntax" Distribution.Compiler
import "Cabal-syntax" Distribution.Pretty (prettyShow)
import "Cabal-syntax" Distribution.Types.BuildInfo
import "Cabal-syntax" Distribution.Types.CondTree
import "Cabal-syntax" Distribution.Types.Dependency
import "Cabal-syntax" Distribution.Types.GenericPackageDescription
import "Cabal-syntax" Distribution.Types.Library
import "Cabal-syntax" Distribution.Types.LibraryName
import "Cabal-syntax" Distribution.Types.PackageDescription
import "Cabal-syntax" Distribution.Types.PackageId
import "Cabal-syntax" Distribution.Types.PackageName

data Buck2PackageDesc = Buck2PackageDesc
  { directory :: String,
    sources :: [String],
    extensions :: [String],
    options :: [String],
    dependencies :: [String]
  }
  deriving (Show)

parseCabal :: FilePath -> IO (Map String Buck2PackageDesc)
parseCabal filepath = do
  genPkgDesc <- readPackage filepath
  let name = unPackageName genPkgDesc.packageDescription.package.pkgName
  let (srcs, extensions, options, dependencies) = flip foldMap (genPkgDesc.condLibrary) $ \case
        CondNode {condTreeData = library@Library {libName = LMainLibName}} ->
          ( map prettyShow library.libBuildInfo.hsSourceDirs,
            map prettyShow library.libBuildInfo.defaultExtensions,
            fold library.libBuildInfo.options,
            map (unPackageName . depPkgName) library.libBuildInfo.targetBuildDepends
          )
        _ -> mempty
  pure $
    Map.singleton name $
      Buck2PackageDesc
        { directory = takeDirectory filepath,
          sources = srcs,
          extensions = extensions,
          options = options,
          dependencies = dependencies
        }

collectCabals :: FilePath -> IO (Map String Buck2PackageDesc)
collectCabals = flip pathWalkAccumulate $ \dir _ files ->
  case find isCabal files of
    Nothing -> mempty
    Just cabal -> parseCabal $ dir </> cabal
  where
    isCabal filepath = takeExtension filepath == ".cabal"

main :: IO ()
main = do
  pPrint =<< parseCabal "amazonka/lib/amazonka/amazonka.cabal"
  pPrint =<< collectCabals "amazonka/lib"
  genPkgDesc <- readPackage "amazonka/lib/amazonka/amazonka.cabal"
  putStrLn $ "name: " ++ unPackageName genPkgDesc.packageDescription.package.pkgName
  flip foldMap (genPkgDesc.condLibrary) $ \case
    CondNode {condTreeData = library@Library {libName = LMainLibName}} -> do
      pPrint $ map prettyShow library.libBuildInfo.defaultExtensions
      pPrint $ fold library.libBuildInfo.options
      pPrint $ map (unPackageName . depPkgName) library.libBuildInfo.targetBuildDepends
      pPrint $ library
    _ -> pure ()
  -- putStrLn $ "name: " ++ genPkgDesc.packageDescription.package.pkgName
  putStrLn "============================================================"
  pPrint genPkgDesc
