# coding: UTF-8

require 'fileutils'
require 'git'
require 'thor'
require 'tmpdir'
require 'yaml'

module Codger
  class CLI < Thor
    desc 'cache GENERATOR', 'keep a local clone of the generator from the given location'
    def cache identifier
      Manager.default.cache identifier
    end

    desc 'cached', 'list all cached generators'
    def cached
      Manager.default.settings[:cached].each do |identifier, _|
        puts identifier
      end
    end

    desc 'uncache GENERATOR', 'remove local clone of a generator'
    def uncache identifier
      Manager.default.uncache identifier
    end

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

    desc 'gen GENERATOR [PATH]', 'run the specified generator at the given path or the current working directory'
    method_option :record, aliases: '-r', type: :boolean, desc: 'record this run in a .codger file in the directory'
    def gen identifier, path='.'
      path = File.expand_path path
      unless File.exists? path
        FileUtils.mkdir path
        Git.init path
      end
      manager = Manager.new File.join(path, '.codger')
      generator = manager.generator identifier
      generator.run path
      manager.record_run generator if options[:record]
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
  end
end
