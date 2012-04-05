require 'erb'
require 'fileutils'
require 'git'

module Codger
  # A generator that produces code by using a git repository as a template.
  #
  # By default:
  # * README, README.md, README.markdown will be ignored, except to
  #   be printed as documentation if user input is required for the
  #   value of a param
  # * generate.rb (if it exists) will be executed in the context of
  #   the Skeleton instance
  # * Files ending in .erb will be interpolated in the context of
  #   the Skeleton instance
  # * All other files will be copied directly
  #
  # Methods for use in generate.rb and templates:
  # * #src_path
  # * #cancel
  # * #copy
  # * #interpolate
  # * #ignore
  # * #rename
  class Skeleton < Generator
    # Returns a (non-unique) name for the generator. For
    # skeletons this is based on the last segment of the origin
    # URI or of the clone's path.
    attr_reader :name
    # Returns the identifier that can (hopefully) be used to locate this skeleton in the future.
    attr_reader :identifier

    # Create an instance reading from the git repository at the specified (local)
    # path.
    def initialize clone, identifier
      @identifier = identifier
      @git = Git.open(clone)
      @name = identifier.split('/').last.sub(/\.git\z/,'')
    end

    # Perform code generation using the process outlined in the class documentation.
    def generate
      @to_copy = @git.ls_files.keys - ['README', 'README.md', 'README.markdown', 'generate.rb', '.gitignore']

      code_path = src_path('generate.rb')
      if File.exists?(code_path)
        eval(File.read(code_path), binding, code_path)
      end

      interpolate(@to_copy.select {|path| path =~ /\.erb\z/})
      copy @to_copy
    end

    # Return the full path to the given file in the repo.
    def src_path(path)
      File.join(@git.dir.to_s, path)
    end

    # For each path or array of paths, copy the
    # corresponding files directly from the repository to
    # the target directory.
    # Alternatively, a hash of paths may be given, in which
    # keys specify the name in the source repository and
    # values specify the desired name in the target directory.
    def copy(*paths)
      paths = paths.flatten
      mappings = {}
      paths.each do |path|
        if path.is_a? Hash
          mappings.merge! path
        else
          mappings[path] = path
        end
      end

      mappings.each do |src, dest|
        ensure_folder dest
        FileUtils.cp src_path(src), dest_path(dest)
        @to_copy.delete src
      end
    end

    # For each path or array of paths, interpolate (in the
    # context of this object) the corresponding files and
    # write the output to the target directory, stripping
    # .erb from the filename.
    # Alternatively, a hash of paths may be given, in which
    # keys specify the name in the source repository and
    # values specify the desired name in the target directory.
    #
    # Note that calls to #rename may override the destination path.
    def interpolate(*paths)
      paths = paths.flatten
      mappings = {}
      paths.each do |path|
        if path.is_a? Hash
          mappings.merge! path
        else
          mappings[path] = path.sub(/\.erb\z/, '')
        end
      end

      mappings.each do |src, dest|
        begin
          @current_template_src = src
          @current_template_dest = dest
          template = ERB.new(File.read(src_path(src)), nil, '-')
          result = template.result(binding)
          ensure_folder @current_template_dest
          File.write File.expand_path(dest_path(@current_template_dest)), result
        rescue CancelInterpolation
        end
        @to_copy.delete src
      end
    end

    # Should only be called from within a file being interpolated.
    # The output path will be changed to dest, which should be
    # relative to the template's folder.
    def rename(dest)
      @current_template_dest = File.join(File.dirname(@current_template_src), dest)
    end

    # Stop interpolation of the current template.
    def cancel
      raise CancelInterpolation.new
    end

    # For each path or array of paths, disable implicit copying.
    def ignore(*paths)
      @to_copy -= paths.flatten
    end

    # Returns the text of the README, README.md or README.markdown file, if any.
    def help
      path = Dir[src_path('README')].first || Dir[src_path('README.md')].first || Dir[src_path('README.markdown')].first
      if path
        File.read path
      end
    end
  end

  class CancelInterpolation < StandardError; end
end