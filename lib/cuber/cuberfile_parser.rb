module Cuber
  class CuberfileParser
    def initialize
      @app = nil
      @build = true
      @labels = {}
      @hostname = nil
      @release = nil
      @repo = nil
      @buildpacks = nil
      @dockerfile = nil
      @image = nil
      @cache = nil
      @dockerconfig = nil
      @kubeconfig = nil
      @migrate = nil
      @procs = {}
      @cron = {}
      @secrets = {}
      @env = {}
      @health = nil
      @lb = {}
      @ingress = nil
      @actioncable_ingress = {}
      @ssl = nil
    end

    def method_missing m, *args
      abort "Cuberfile: \"#{m}\" is not a command"
    end

    def app name
      @app = name
    end

    def build enabled = true
      @build = enabled
    end

    def labels key, value
      @labels[key] = value
    end

    def hostname hostname
      @hostname = hostname
    end

    def release version
      @release = version
    end

    def repo url, branch: nil
      @repo = { url: url, branch: branch }
    end

    def buildpacks builder
      @buildpacks = builder
    end

    def dockerfile path
      @dockerfile = path
    end

    def image name
      @image = name
    end

    def cache enabled
      @cache = enabled
    end

    def dockerconfig path
      @dockerconfig = path
    end

    def kubeconfig path
      @kubeconfig = path
    end

    def migrate cmd, check: nil
      @migrate = { cmd: cmd, check: check }
    end

    def proc name, cmd, scale: 1, cpu: nil, ram: nil, term: 60, env: {}
      @procs[name] = { cmd: cmd, scale: scale, cpu: cpu, ram: ram, term: term, env: env }
    end

    def cron name, schedule, cmd
      @cron[name] = { schedule: schedule, cmd: cmd }
    end

    def env key, value, secret: false
      secret ? (@secrets[key] = value) : (@env[key] = value)
    end

    def health url
      @health = url
    end

    def lb key, value
      @lb[key] = value
    end

    def ingress enabled
      @ingress = enabled
    end

    def ssl enabled, crt = nil, key = nil
      @ssl = crt && key ? { crt: crt, key: key } : enabled
    end

    def actioncable_ingress hostname:, mount_path:, lb: {}
      @actioncable_ingress = { hostname: hostname, mount_path: mount_path, lb: lb }
    end
  end
end
