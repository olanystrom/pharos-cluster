# frozen_string_literal: true

require_relative 'debian'

module Pharos
  module Host
    class DebianStretch < Debian
      register_config 'debian', '9'

      CFSSL_VERSION = '1.2'
      DOCKER_VERSION = '18.06.1'

      register_component(
        name: 'cri-o', version: CRIO_VERSION, license: 'Apache License 2.0',
        enabled: proc { |c| c.hosts.any? { |h| h.container_runtime == 'cri-o' } }
      )

      register_component(
        name: 'cfssl', version: CFSSL_VERSION, license: 'MIT',
        enabled: proc { |c| !c.etcd&.endpoints }
      )

      register_component(
        name: 'docker-ce', version: DOCKER_VERSION, license: 'Apache License 2.0',
        enabled: proc { |c| c.hosts.any? { |h| h.container_runtime == 'docker' } }
      )

      def configure_repos
        exec_script("repos/pharos_stretch.sh")
        exec_script('repos/update.sh')
      end

      def configure_container_runtime
        if docker?
          exec_script(
            'configure-docker.sh',
            DOCKER_PACKAGE: 'docker-ce',
            DOCKER_VERSION: "#{DOCKER_VERSION}~3-0~debian",
            INSECURE_REGISTRIES: insecure_registries
          )
        elsif custom_docker?
          exec_script(
            'configure-docker.sh',
            INSECURE_REGISTRIES: insecure_registries
          )
        elsif crio?
          exec_script(
            'configure-cri-o.sh',
            CRIO_VERSION: Pharos::CRIO_VERSION,
            CRIO_STREAM_ADDRESS: '127.0.0.1',
            CPU_ARCH: host.cpu_arch.name,
            IMAGE_REPO: cluster_config.image_repository,
            INSECURE_REGISTRIES: insecure_registries
          )
        else
          raise Pharos::Error, "Unknown container runtime: #{host.container_runtime}"
        end
      end

      def reset
        exec_script(
          "reset.sh",
          CRIO_VERSION: CRIO_VERSION
        )
      end
    end
  end
end