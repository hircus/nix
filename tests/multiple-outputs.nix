with import ./config.nix;

rec {

  a = mkDerivation {
    name = "multiple-outputs-a";
    outputs = [ "first" "second" ];
    builder = builtins.toFile "builder.sh"
      ''
        mkdir $first $second
        test -z $all
        echo "second" > $first/file
        echo "first" > $second/file
      '';
    helloString = "Hello, world!";
  };

  b = mkDerivation {
    defaultOutput = assert a.second.helloString == "Hello, world!"; a;
    firstOutput = assert a.outputName == "first"; a.first.first;
    secondOutput = assert a.second.outputName == "second"; a.second.first.first.second.second.first.second;
    allOutputs = a.all;
    name = "multiple-outputs-b";
    builder = builtins.toFile "builder.sh"
      ''
        mkdir $out
        test "$firstOutput $secondOutput" = "$allOutputs"
        test "$defaultOutput" = "$firstOutput"
        test "$(cat $firstOutput/file)" = "second"
        test "$(cat $secondOutput/file)" = "first"
        echo "success" > $out/file
      '';
  };

  c = mkDerivation {
    name = "multiple-outputs-c";
    drv = b.drvPath;
    builder = builtins.toFile "builder.sh"
      ''
        mkdir $out
        ln -s $drv $out/drv
      '';
  };

  d = mkDerivation {
    name = "multiple-outputs-d";
    drv = builtins.unsafeDiscardOutputDependency b.drvPath;
    builder = builtins.toFile "builder.sh"
      ''
        mkdir $out
        echo $drv > $out/drv
      '';
  };

  cyclic = (mkDerivation {
    name = "cyclic-outputs";
    outputs = [ "a" "b" "c" ];
    builder = builtins.toFile "builder.sh"
      ''
        mkdir $a $b $c
        echo $a > $b/foo
        echo $b > $c/bar
        echo $c > $a/baz
      '';
  }).a;

}
