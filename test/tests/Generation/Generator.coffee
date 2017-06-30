{Generator, MiniFoundation} = Generation

{log} = MiniFoundation

suite "NeptuneNamespaces.Generator", ->
  test "basic", ->
    generator = new Generator "root", pretend: true, quiet: true
    generator.generateFromFiles [
        "root/file.coffee"
      ]
    .then ({generatedFiles, namespaces}) ->
      assert.match generatedFiles["root/index.coffee"], /File.*require.*\.\/file/
      assert.match generatedFiles["root/namespace.coffee"], /class Root/

  test "file comment should be relative to root's parent", ->
    generator = new Generator root = "/Users/alice/dev/src/MyApp", pretend: true, quiet: true
    generator.generateFromFiles [
        "#{root}/Module.coffee"
        "#{root}/SubNamespace/SubModule.coffee"
      ]
    .then ({generatedFiles, namespaces}) ->
      for file, contents of generatedFiles
        assert.match contents, "# file: MyApp", file

  test "file name same as parent namespace", ->
    generator = new Generator root = "root", pretend: true, quiet: true
    generator.generateFromFiles [
        "root/MyNamespace/my_namespace.coffee"
      ]
    .then ({generatedFiles, namespaces}) ->
      # log ((v for k, v of generatedFiles).join "\n\n")
      assert.match generatedFiles["root/MyNamespace/index.coffee"], /includeInNamespace.*my_namespace/

  test "special file names", ->
    generator = new Generator "root", pretend: true, quiet: true
    generator.generateFromFiles [
        "root/.file1.coffee"
        "root/root.coffee"
        "root/file4.coffee"
        "root/0file3.coffee"
        "root/-file2.coffee"
        "root/_file5.coffee"
        "root/aSubmodule/foo.coffee"
      ]
    .then ({generatedFiles, namespaces}) ->
      # log generatedFiles
      assert.match generatedFiles["root/index.coffee"],
        ///
        file2
        (.|\n)*

        module.exports .* namespace
        (.|\n)*

        includeInNamespace .* root
        (.|\n)*

        addModules
        (.|\n)*

        File5: .* _file5
        (.|\n)*

        File3: .* 0file3
        (.|\n)*

        File4: .* file4
        (.|\n)*

        \nrequire .* aSubmodule
        ///
      # file1 not included
      assert.doesNotMatch generatedFiles["root/index.coffee"], /file1/
      assert.eq Object.keys(generatedFiles).sort(), [
        "root/aSubmodule/index.coffee"
        "root/aSubmodule/namespace.coffee"
        "root/index.coffee"
        "root/namespace.coffee"
      ]

  test "subnamespace", ->
    generator = new Generator "root", pretend: true, quiet: true
    generator.generateFromFiles [
        "root/MyNamespace/file.coffee"
      ]
    .then ({generatedFiles, namespaces}) ->
      assert.eq Object.keys(generatedFiles).sort(), [
        "root/MyNamespace/index.coffee"
        "root/MyNamespace/namespace.coffee"
        "root/index.coffee"
        "root/namespace.coffee"
      ]
      assert.match generatedFiles["root/MyNamespace/namespace.coffee"], /require.*\.\/namespace/
      assert.match generatedFiles["root/namespace.coffee"], /require.*neptune-namespaces/
      assert.doesNotMatch generatedFiles["root/index.coffee"], "addModules"
      assert.match generatedFiles["root/index.coffee"], "MyNamespace"

  test ".namespaces are optional", ->
    generator = new Generator "root", pretend: true, quiet: true
    generator.generateFromFiles [
        "root/.MyNamespace/file.coffee"
      ]
    .then ({generatedFiles, namespaces}) ->
      assert.eq Object.keys(generatedFiles).sort(), [
        "root/.MyNamespace/index.coffee"
        "root/.MyNamespace/namespace.coffee"
        "root/index.coffee"
        "root/namespace.coffee"
      ]
      assert.match generatedFiles["root/.MyNamespace/namespace.coffee"], /require.*\.\/namespace/
      assert.match generatedFiles["root/namespace.coffee"], /require.*neptune-namespaces/
      assert.doesNotMatch generatedFiles["root/index.coffee"], "addModules"
      assert.doesNotMatch generatedFiles["root/index.coffee"], "MyNamespace"


  test "non-dot-namespaces with same-name-dot-file are not optional", ->
    generator = new Generator "root", pretend: true, quiet: true
    generator.generateFromFiles [
        "root/MyNamespace/file.coffee"
        "root/.my_namespace.coffee"
      ]
    .then ({generatedFiles, namespaces}) ->
      assert.eq Object.keys(generatedFiles).sort(), [
        "root/MyNamespace/index.coffee"
        "root/MyNamespace/namespace.coffee"
        "root/index.coffee"
        "root/namespace.coffee"
      ]
      assert.match generatedFiles["root/MyNamespace/namespace.coffee"], /require.*\.\/namespace/
      assert.match generatedFiles["root/namespace.coffee"], /require.*neptune-namespaces/
      assert.doesNotMatch generatedFiles["root/index.coffee"], "addModules"
      assert.match generatedFiles["root/index.coffee"], "MyNamespace"

  test "only file is required if directory and file have same name", ->
    generator = new Generator "root", pretend: true, quiet: true
    generator.generateFromFiles [
        "root/MyNamespace/file.coffee"
        "root/my_namespace.coffee"
      ]
    .then ({generatedFiles, namespaces}) ->
      assert.eq Object.keys(generatedFiles).sort(), [
        "root/MyNamespace/index.coffee"
        "root/MyNamespace/namespace.coffee"
        "root/index.coffee"
        "root/namespace.coffee"
      ]
      assert.match generatedFiles["root/MyNamespace/namespace.coffee"], /require.*\.\/namespace/
      assert.match generatedFiles["root/namespace.coffee"], /require.*neptune-namespaces/
      assert.match generatedFiles["root/index.coffee"], "addModules"
      assert.doesNotMatch generatedFiles["root/index.coffee"], /(^|\n)require.*MyNamespace/

  test "pathed explicitly", ->
    generator = new Generator "root", pretend: true, quiet: true
    generator.generateFromFiles [
        "root/Alpha.Beta/file.coffee"
      ]
    .then ({generatedFiles, namespaces}) ->
      assert.eq Object.keys(generatedFiles).sort(), [
        "root/Alpha.Beta/index.coffee"
        "root/Alpha.Beta/namespace.coffee"
        "root/index.coffee"
        "root/namespace.coffee"
      ]
      assert.match generatedFiles["root/Alpha.Beta/namespace.coffee"], /// addNamespace .* Alpha\.Beta .* class\ Beta ///
      assert.match generatedFiles["root/index.coffee"], /// require.*\./Alpha\.Beta ///
      assert.match generatedFiles["root/namespace.coffee"], /// require.*\./Alpha\.Beta ///

  test "pathed implicitly", ->
    generator = new Generator "root", pretend: true, quiet: true
    generator.generateFromFiles [
        "root/Alpha/Beta/file.coffee"
      ]
    .then ({generatedFiles, namespaces}) ->
      assert.eq Object.keys(generatedFiles).sort(), [
        "root/Alpha/Beta/index.coffee"
        "root/Alpha/Beta/namespace.coffee"
        "root/Alpha/index.coffee"
        "root/Alpha/namespace.coffee"
        "root/index.coffee"
        "root/namespace.coffee"
      ]
      log {generatedFiles}
      assert.match generatedFiles["root/Alpha/namespace.coffee"], /// vivifiySubnamespace.*Alpha ///

  test "pathed both ways", ->
    generator = new Generator "root", pretend: true, quiet: true
    generator.generateFromFiles [
        "root/Alpha.Beta/Gamma/file.coffee"
      ]
    .then ({generatedFiles, namespaces}) ->
      assert.eq Object.keys(generatedFiles).sort(), [
        "root/Alpha.Beta/Gamma/index.coffee"
        "root/Alpha.Beta/Gamma/namespace.coffee"
        "root/Alpha.Beta/index.coffee"
        "root/Alpha.Beta/namespace.coffee"
        "root/index.coffee"
        "root/namespace.coffee"
      ]
      assert.match generatedFiles["root/Alpha.Beta/Gamma/namespace.coffee"],  /// require .* '\.\./namespace'     .* addNamespace        .* Gamma       ///
      assert.match generatedFiles["root/Alpha.Beta/namespace.coffee"],        /// require .* 'neptune-namespaces' .* vivifiySubnamespace .* Alpha\.Beta ///

  test "pathed explicitly with includeInNamespace", ->
    generator = new Generator "root", pretend: true, quiet: true
    generator.generateFromFiles [
        "root/Alpha.Beta/file.coffee"
        "root/Alpha.Beta/Beta.coffee"
      ]
    .then ({generatedFiles, namespaces}) ->
      assert.eq Object.keys(generatedFiles).sort(), [
        "root/Alpha.Beta/index.coffee"
        "root/Alpha.Beta/namespace.coffee"
        "root/index.coffee"
        "root/namespace.coffee"
      ]
      assert.match generatedFiles["root/Alpha.Beta/index.coffee"], /// includeInNamespace .* \.\/Beta ///
