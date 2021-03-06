module Gerrit::Command
  # Sets up the remotes for this repository to push/pull to/from Gerrit.
  class Setup < Base
    def execute
      remotes_to_add = config[:remotes]
      existing_remotes = repo.remotes.keys & remotes_to_add.keys

      if existing_remotes.any?
        return unless can_replace?(existing_remotes)
      end

      add_remotes(remotes_to_add)
    end

    private

    def can_replace?(existing_remotes)
      ui.warning 'The following remotes already exist and will be replaced:'
      existing_remotes.each do |remote|
        ui.info remote
      end

      ui.newline
      ui.ask('Replace them? (y/n)[n]')
        .argument(:required)
        .default('n')
        .modify(:downcase)
        .read_string == 'y'
    end

    def add_remotes(remotes)
      remotes.each do |remote_name, remote_config|
        remote_url = render_remote_url(remote_config)

        `git remote rm #{remote_name} &> /dev/null`
        `git remote add #{remote_name} #{remote_url}`

        if remote_config['push']
          `git config remote.#{remote_name}.push #{remote_config['push']}`
        end

        ui.success "Added #{remote_name} #{remote_url}"
      end

      ui.newline
      ui.info 'You can now push commits for review by running: ', newline: false
      ui.print 'gerrit push'
    end

    def render_remote_url(remote_config)
      remote_config['url'] % {
        user: config[:user],
        host: config[:host],
        port: config[:port],
        project: project_name,
      }
    end

    # Allow a project name to be explicitly specified, otherwise just use the
    # repo root directory name.
    def project_name
      if arguments[2]
        arguments[2]
      else
        File.basename(repo.root)
      end
    end
  end
end
