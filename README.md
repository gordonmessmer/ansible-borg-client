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

