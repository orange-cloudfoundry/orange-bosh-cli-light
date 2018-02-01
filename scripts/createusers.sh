#!/bin/bash
# This script should be placed in /etc/profile.d
# It creates sample DEST_DIRectories wich should be shared accross several containers

for var in ${CONTAINER_USERS};
do
	user=$(echo $var | cut -f1 -d:)
	SSH_PUBLIC_KEY=$(echo $var | cut -f2 -d:)
	if ! id ${user} >/dev/null 2>&1; then
		useradd -m -g users -G sudo -s /bin/bash ${user}
		echo "${user}:${CONTAINER_PASSWORD}" | chpasswd
		mkdir -p /home/${user}/.ssh
		chmod 700 /home/${user}/.ssh
		chown ${user}:users /home/${user}/.ssh
		if [[ "$SSH_PUBLIC_KEY" != "ssh-rsa"* ]]
		then
			SSH_PUBLIC_KEY="ssh-rsa $SSH_PUBLIC_KEY public.key@pushed"
		fi
		echo "$SSH_PUBLIC_KEY" > /home/${user}/.ssh/authorized_keys
		chmod 600 /home/${user}/.ssh/authorized_keys
		chown ${user}:users /home/${user}/.ssh/authorized_keys
		echo "SSH public key provided threw env variable. Enabling public key auth done."

		/usr/local/bin/disable_ssh_password_auth ${user}

		echo "${user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${user}
	fi
done

