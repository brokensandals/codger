require 'yaml'

module Codger
  # A code generator. The #run method is called to perform code generation;
  # the parameters used (which may have been specified interactively during #run)
  # can be determined afterwards using #params.
  #
  # Subclasses must implement:
  # * a #generate method which will perform the code generation
  # * a #help method which returns help text
  #
  # Methods for use by subclasses:
  # * #dest_path
  # * #ensure_folder
  # * #param
  # * #tags
  class Generator
    class << self
      # Given a params map, print one param per line, indented.
      def format_params(params)
        YAML.dump(params).lines.drop(1).map do |line|
          "\t#{line}"
        end.join
      end
    end

    # The map of parameters used during the last call to #run.
    attr_reader :params
    # The output directory used during the last call to #run.
    attr_reader :target

    # Perform code generation in the given directory. Any parameters
    # already known (e.g., if we're repeating a previous run) can be
    # specified; any other parameters needed will be determined interactively.
    def run(target, params = {})
      @showed_help = false
      @target = target
      @params = params.with_indifferent_access

      generate
    end

    # Given a path relative to the output directory root, returns the full path.
    def dest_path(path)
      File.join(target, path)
    end

    # Given a path relative to the output directory root, creates a folder
    # at that location if one does not yet exist.
    def ensure_folder(path)
      FileUtils.mkdir_p(File.expand_path(File.join(target, File.dirname(path))))
    end

    # Returns the value from the params map for the given name. If there
    # is none, asks the user for a value. #help is called the first time
    # the user is asked for a value.
    # The parameter will also be saved in an instance variable of the same name.
    def param(name)
      until params[name]
        unless @showed_help
          puts help
          puts
          @showed_help = true
        end
        print "Specify #{name}: "
        value = STDIN.gets.chomp
        params[name] = value unless value.empty?
      end
      instance_variable_set("@#{name}", params[name])
      params[name]
    end

    # Sets (with parameters) or returns (without parameters) tags for
    # this generator. The tags will be associated to recorded runs.
    # (This may be useless, we'll see.)
    def tags(*tags)
      if tags == []
        @tags || []
      else
        @tags = tags.flatten
      end
    end
  end
end
