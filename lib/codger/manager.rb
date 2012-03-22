require 'fileutils'
require 'git'
require 'yaml'

module Codger
  # Responsible for:
  # * Reading, writing, and to some degree interpreting configuration files.
  # * Looking up code generators from their identifiers.
  class Manager
    class << self
      # Return an instance using any settings in the .codger
      # file (if one exists) of the working directory.
      def default
        @config ||= Manager.new(File.join(Dir.pwd, '.codger'))
      end
    end

    # The global settings map (i.e. from ~/.codger/codger.yaml)
    attr_reader :global_settings
    # The project settings map (i.e. from .codger)
    attr_reader :project_settings

    # Create an instance with project-level settings stored at the specified path
    # (does not need to exist yet, and will not be created unless necessary).
    def initialize(path)
      @project_path = path
      @project_settings = {
        runs: []
      }.with_indifferent_access
      if File.exists?(@project_path)
        @project_settings.merge! YAML.load(File.read(@project_path))
      end

      @global_settings = {
        config: {
          diff: 'diff -ur %SOURCE %DEST'
        }
      }.with_indifferent_access
      if File.exists?(globals_path)
        @global_settings.merge! YAML.load(File.read(globals_path))
      end
    end

    # Creates a Generator, currently always a Skeleton.
    # id can be:
    # * a filesystem path, which will be used directly
    # * a git uri, which will be cloned to a temporary directory
    def generator(id)
      if File.exists? id
        clone = id
        id = File.expand_path id
      else
        clone = Dir.mktmpdir
        Git.clone id, clone
        at_exit do
          raise "I'm scared to delete #{clone}" unless clone.size > 10 # just being paranoid before rm_rf'ing
          FileUtils.rm_rf clone
        end
      end
      Skeleton.new clone, id
    end

    # Saves the tags, identifier, and params from the last run of the given generator instance
    # in the project settings file.
    def record_run(generator)
      @project_settings[:runs] << {
        tags: [generator.name] + generator.tags,
        generator: generator.identifier,
        params: generator.params
      }.with_indifferent_access
      save_project
    end

    # Save #project_settings.
    def save_project
      File.write @project_path, @project_settings.to_yaml
    end

    # Save #global_settings.
    def save_globals
      FileUtils.mkdir_p codger_home
      File.write globals_path, @global_settings.to_yaml
    end

    # Return the folder where global settings and other resources can be saved.
    # By default ~/.codger but this can be overridden using 'codger_home' in #project_settings.
    def codger_home
      @project_settings[:codger_home] || File.join(Dir.home, '.codger')
    end

    # Return the file where global settings should be saved - 'codger.yaml' in #codger_home.
    def globals_path
      File.join(codger_home, 'codger.yaml')
    end

    # Return a merged map of #global_settings and #project_settings.
    def settings
      @global_settings.deep_merge @project_settings
    end

    # Return the command to use for diffing two folders.
    def diff_command(source, dest)
      settings[:config][:diff].gsub('%SOURCE', source).gsub('%DEST', dest)
    end
  end
end
