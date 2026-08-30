# run-borg setup notes

## site config

The hostname of your backup server should be set in group_vars/all.

run-borg will exit early if this hostname can't be resolved.  One of my backup
servers only resolves when I'm at home, on my own private domain, so I want the
script to exit and do nothing when I can't reach that server.

## host config

Add each of your clients to the inventory in hosts/hosts, along with the name
of the user on the backup server which will be used for the ssh connection.

I run this backup job as the root user so that I can include /etc in my backup
set.  If you only want to back up your home directory, then most of this could
be done within your own user profile, and I'd be happy to take a pull request
that implements such a variation.

There are a few steps that the playbook does not perform automatically:

1. The script must be able to log in to the storage server automatically.  Set
   up ssh key login as usual.
2. Create a directory on that server to store your backups:
   mkdir /var/backup/borgbackup/$USER
3. Mount that directory on your client using sshfs:
   sshfs $USER@server:/var/backup/borgbackup/$USER ~/backups
4. Initialize the borg backup directory:
   borg init --encryption=authenticated ~/backups
5. Reserve some space on disk:
   borg config ~/backups additional_free_space 2G

## Atomic / bootc hosts

On an immutable host (Fedora Atomic, bootc) borg can't be layered in with the
package manager, so instead of installing it on the host we run the same
run-borg script inside a container on a timer.

Add these hosts to the `[atomic]` group in hosts/hosts.  They use the
`borgbackup_container` role, which installs a `run-borg.service` that launches
the image with `podman run`.  The host's /etc and /home are bind-mounted into
the container read-only as the backup sources, and /root/.ssh is mounted so
the container can reach the storage server.

The image is built on the control node:

1. Build the container image:
     podman build -t fedora-python .
2. Run the playbook:
     ansible-playbook -i hosts/hosts site.yml
   For Atomic hosts the role exports the freshly built image from the control
   node's podman storage, copies the tarball to the host, and loads it into the
   host's root podman storage.  This only happens when the host's copy is
   missing or out of date, so re-running the playbook doesn't re-transfer the
   image unnecessarily.

The manual prerequisites above (ssh key login as root, creating the remote
directory, `borg init`, reserving space) apply to Atomic hosts too.

