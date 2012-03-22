# coding: UTF-8

require 'fileutils'
require 'git'
require 'thor'
require 'tmpdir'
require 'yaml'

module Codger
  class CLI < Thor
    desc 'config [NAME [VALUE]]', 'lists, shows, or alters configuration'
    def config(name = nil, value = nil)
      if name
        if value
          Manager.default.global_settings[:config][name] = value
          Manager.default.save_globals
        else
          puts Manager.default.settings[:config][name]
        end
      else
        puts YAML.dump(Manager.default.settings[:config]).lines.drop(1).join
      end
    end

    desc 'available', 'lists registered code generators'
    def available
      Manager.default.settings[:generators].each do |name, info|
        puts "#{name}\t#{info.inspect}"
      end
    end

    desc 'skeleton LOCATION', 'register a git repository as a code generator, creating a clone from the given location'
    method_option :name, desc: 'Name you wish to refer to the skeleton by.'
    method_option :test, desc: 'Prevent cloning or pulling of the repository. Location should be a path on the file system.'
    def skeleton(location)
      info = {}
      if options[:test]
        location = File.expand_path(location)
        info[:test] = true
      end
      info[:git] = location
      Manager.default.register options[:name], info
    end

    desc 'gen NAME [PATH]', 'run the specified generator at the given path or the current working directory'
    def gen name, path='.'
      path = File.expand_path path
      unless File.exists? path
        FileUtils.mkdir path
        Git.init path
      end
      manager = Manager.new File.join(path, '.codger')
      generator = manager.generator manager.settings[:generators][name]
      generator.run path
      manager.record_run generator
    end

    desc 'history', 'show the actions recorded for this directory'
    def history
      Manager.default.settings[:runs].each do |info|
        puts "#{info[:generator]} [#{info[:tags].join(' ')}]"
        puts Generator.format_params(info[:params])
        puts
      end
    end

    desc 'diff [TAGS...]', 'run part or all of the history in a temp directory and display a diff'
    def diff(*tags)
      Dir.mktmpdir do |dir|
        Manager.default.settings[:runs].each do |info|
          if tags.empty? or (tags & info[:tags]).any?
            generator = Manager.default.generator(info[:generator])
            generator.run dir, info[:params]
          end
        end
        system Manager.default.diff_command(dir, Dir.pwd)
      end
    end

    desc 'repeat [TAGS...]', 're-run part or all of the history'
    def repeat(*tags)
      Manager.default.settings[:runs].each do |info|
        if tags.empty? or (tags & info[:tags]).any?
          puts "Running #{info[:generator]} [#{info[:tags].join(' ')}]"
          puts Generator.format_params(info[:params])
          puts
          generator = Manager.default.generator(info[:generator])
          generator.run Dir.pwd, info[:params]
        end
      end
    end

    desc 'unregister NAME', 'unregister a code generator and delete its clone'
    def unregister(name)
      Manager.default.unregister name
    end
  end
end
