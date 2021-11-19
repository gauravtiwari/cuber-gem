module Cuber::Commands
  class Info
    include Cuber::Utils

    def initialize options
      @options = options
      @namespace = nil
    end

    def execute
      set_namespace
      print_app_version
      print_public_ip
      print_env
      print_migration
      print_proc
      print_cron
      print_issues
    end

    private

    def set_namespace
      @namespace = kubeget 'namespace', @options[:app]
      abort 'Cuber: app not found' if @namespace.dig('metadata', 'labels', 'app.kubernetes.io/managed-by') != 'cuber'
    end

    def print_section title
      puts
      puts "\e[34m=== #{title}\e[0m"
    end

    def print_app_version
      print_section 'App'
      puts "#{@namespace['metadata']['labels']['app.kubernetes.io/name']}"
      puts "version #{@namespace['metadata']['labels']['app.kubernetes.io/version']}"
    end

    def print_public_ip
      print_section 'Public IP'
      json = kubeget 'service', 'load-balancer'
      puts "#{json['status']['loadBalancer']['ingress'][0]['ip']}"
    end

    def print_env
      print_section 'Env'
      json = kubeget 'configmap', 'env'
      json['data']&.each do |key, value|
        puts "#{key}=#{value}"
      end
      json = kubeget 'secrets', 'app-secrets'
      json['data']&.each do |key, value|
        puts "#{key}=#{Base64.decode64(value)[0...5] + '***'}"
      end
    end

    def print_migration
      print_section 'Migration'
      migration = "migrate-#{@namespace['metadata']['labels']['app.kubernetes.io/instance']}"
      json = kubeget 'job', migration, '--ignore-not-found'
      if json
        migration_command = json['spec']['template']['spec']['containers'][0]['command'].shelljoin
        migration_status = json['status']['succeeded'].to_i.zero? ? 'Pending' : 'Completed'
        puts "migrate: #{migration_command} (#{migration_status})"
      else
        puts "None detected"
      end
    end

    def print_proc
      print_section 'Proc'
      json = kubeget 'deployments'
      json['items'].each do |proc|
        name = proc['metadata']['name']
        command = proc['spec']['template']['spec']['containers'][0]['command'].shelljoin
        available = proc['status']['availableReplicas'].to_i
        updated = proc['status']['updatedReplicas'].to_i
        replicas = proc['status']['replicas'].to_i
        scale = proc['spec']['replicas'].to_i
        puts "#{name}: #{command} (#{available}/#{scale}) #{'OUT-OF-DATE' if replicas - updated > 0}"
      end
    end

    def print_cron
      print_section 'Cron'
      json = kubeget 'cronjobs'
      json['items'].each do |cron|
        name = cron['metadata']['name']
        schedule = cron['spec']['schedule']
        command = cron['spec']['jobTemplate']['spec']['template']['spec']['containers'][0]['command'].shelljoin
        last = cron['status']['lastScheduleTime']
        puts "#{name}: #{schedule} #{command} (#{time_ago_in_words Time.parse(last)})"
      end
    end

    def print_issues
      print_section 'Issues'
      issues_count = 0
      json = kubeget 'pods'
      json['items'].each do |pod|
        name = pod['metadata']['name']
        pod_status = pod['status']['phase']
        container_ready = pod['status']['containerStatuses'][0]['ready']
        next if pod_status == 'Succeeded'
        if pod_status != 'Running'
          issues_count += 1
          puts "#{name}: #{pod_status}"
        elsif !container_ready
          issues_count += 1
          container_status = pod['status']['containerStatuses'][0]['state'].values.first['reason']
          puts "#{name}: #{container_status}"
        end
      end
      puts "None detected" if issues_count.zero?
    end

    def time_ago_in_words time
      seconds = (Time.now - time).round
      case
      when seconds < 60 then "#{seconds}s"
      when seconds < 60*60 then "#{(seconds / 60)}m"
      when seconds < 60*60*24 then "#{(seconds / 60 / 60)}h"
      else "#{(seconds / 60 / 60 / 24)}d"
      end
    end

  end
end
