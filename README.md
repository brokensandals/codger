# codger

Goals:

* Provide a simple way to define and run project skeletons and other code generators.
* Help integrate later changes to the generators into a project.

## Creating Skeletons

Put the skeleton in a git repo. Before testing it, make sure to at least `git add` the files. Then:

    codger gen path/to/your/repo path/to/new/project

Here's how the skeleton repo will be used:

1. If there is a script named `generate.rb` in the root directory, it will be run.
2. Files ending in `.erb` will be [interpolated](http://ruby-doc.org/stdlib-1.9.3/libdoc/erb/rdoc/ERB.html) and written to the target directory.
3. Other files will be copied directly to the target directory. (Exceptions: README, README.md, README.markdown, .gitignore)

### Parameters

In the templates or generate.rb, use the method `param :parameter_name` to request values to configure the skeleton. The first time a particular parameter is requested, the user will be prompted for a value.

The first time a prompt is given, the skeleton repo's README will be printed (if it exists).

### Helpers

* In a template, you can use `<%- rename "relative_path" -%>` to override the output file name.
* Use `copy "path1", "path2"` to copy files "path1" and "path2" (relative the skeleton repo's root directory) into the target directory directly. Use `copy "path1" => "newpath1"` to override the destination path in the target directory.
* Use `interpolate "path1", "path2"` to interpolate ERB files "path1" and "path2" into the target directory. As with `copy` you can use a hash to override the destination paths.
* Use `cancel` inside a template to stop its interpolation.
* Use `ignore "path1", "path2"` to prevent automatic copying or interpolation of files.

## Using Skeletons

Run in a new folder:

    codger gen boilerplate monumental-endeavor

Or run in the current working directory:

    codger gen boilerplate

### Caching

    codger cache git://uri/to/boilerplate.git # stores a local clone in ~/.codger/cached
    codger gen boilerplate # uses the local clone (but will update it first if possible)

### Diffing

You can add the `-r` (record) option:

    codger gen boilerplate -r

to have the run recorded in a file named `.codger`, so that later, after the project or the skeleton have changed, you can use

    codger diff

to compare the current state of your project with the output of the current version of the skeleton. The command used for diffing can be changed:

    codger config diff "diff -ur %SOURCE %DEST"

## TODO

* Better documentation; examples
* I'm hopeful that more useful diffing can be done through git integration, but I haven't worked on it much yet.
* Code generators shouldn't be restricted to whatever dependencies happen to be pulled in by codger.
