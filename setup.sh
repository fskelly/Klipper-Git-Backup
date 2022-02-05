#!/bin/bash

SPACE=" |'"

echo "Checking if git is installed"

if ! command -v git &> /dev/null
then
        echo "Git is not installed"
        echo "Installing git"
        sudo apt install git -y
else
        echo "Git already installed"
fi

echo ""
echo "Cloning backup script"
#git -C /home/pi/scripts clone https://github.com/Low-Frequency/klipper_backup_script
#chmod +x /home/pi/scripts/klipper_backup_script/klipper_config_git_backup.sh
#chmod +x /home/pi/scripts/klipper_backup_script/restore_config.sh
#chmod +x /home/pi/scripts/klipper_backup_script/uninstall.sh

echo ""
echo "Configuring the script"

echo "##" >> /home/pi/scripts/klipper_backup_script/backup.cfg
echo "## Log Rotation enable/disable" >> /home/pi/scripts/klipper_backup_script/backup.cfg
echo "## 1: enable" >> /home/pi/scripts/klipper_backup_script/backup.cfg
echo "## 0: disable" >> /home/pi/scripts/klipper_backup_script/backup.cfg

echo ""
echo "Do you want to enable log rotation?"
echo "This can save space on your SD card"
echo "This is recommended, if you choose to backup to Google Drive"
echo ""

ROT=9999
while [[ $ROT != 1 && $ROT != 0 ]]
do
	read -p 'Enable log rotation? [y|n] ' ROT

	case $ROT in
		n)
			echo "ROTATION=0" >> /home/pi/scripts/klipper_backup_script/backup.cfg
			echo "Log rotation disabled"
			;;
		y)
                        echo "ROTATION=1" >> /home/pi/scripts/klipper_backup_script/backup.cfg
                        echo "Log rotation enabled"
                        ;;
		*)
			echo "Please provide a valid configuration"
			echo ""
			;;
	esac
done

echo "##" >> /home/pi/scripts/klipper_backup_script/backup.cfg
echo "## Time in months to keep the logs" >> /home/pi/scripts/klipper_backup_script/backup.cfg
echo ""

if [ $ROT = 0 ]
then
	echo "RETENTION=6" >> /home/pi/scripts/klipper_backup_script/backup.cfg
else
	read -p "How long should the logs be kept (in months) " KEEP
	echo "RETENTION=$KEEP" >> /home/pi/scripts/klipper_backup_script/backup.cfg
fi

echo ""
echo "Which backup locations do you want to enable?"
echo "Type y to enable a backup location"
echo "Type n to disable a backup location"
echo ""

echo "##" >> /home/pi/scripts/klipper_backup_script/backup.cfg
echo "## Backup locations enable/disable" >> /home/pi/scripts/klipper_backup_script/backup.cfg
echo "## 1: enable" >> /home/pi/scripts/klipper_backup_script/backup.cfg
echo "## 0: disable" >> /home/pi/scripts/klipper_backup_script/backup.cfg

G=9
C=9
while [[ "$G" != "y" && "$G" != "n" ]]
do
	read -p 'Do you want to enable GitHub as a backup location? [y|n] ' G

	case $G in
		n)
			echo "GitHub backup disabled"
			echo "GIT=0" >> /home/pi/scripts/klipper_backup_script/backup.cfg
			;;
		y)
			echo "GitHub backup enabled"
			echo "GIT=1" >> /home/pi/scripts/klipper_backup_script/backup.cfg
			;;
		*)
			echo "Please provide a valid configuration"
			echo ""
			;;
	esac
done

echo ""

while [[ "$C" != "y" && "$C" != "n" ]]
do
        read -p 'Do you want to enable Google Drive backup? [y|n] ' C

        case $C in
                n)
                        echo "Google Drive backup disabled"
                        echo "CLOUD=0" >> /home/pi/scripts/klipper_backup_script/backup.cfg
                        ;;
                y)
                        echo "Google Drive backup enabled"
                        echo "CLOUD=1" >> /home/pi/scripts/klipper_backup_script/backup.cfg
			chmod +x /home/pi/scripts/klipper_backup_script/drive.exp
			chmod +x /home/pi/scripts/klipper_backup_script/delete_remote.exp
                        ;;
                *)
                        echo "Please provide a valid configuration"
                        echo ""
                        ;;
        esac
done

echo ""
echo "Checking for dierectories"

if [[ -d /home/pi/scripts ]]
then
        echo "Scripts folder already exists"
else
        echo "Crating scripts folder"
        mkdir /home/pi/scripts
fi

if [[ -d /home/pi/backup_log ]]
then
        echo "Log folder already exists"
else
        echo "Creating log folder"
        mkdir /home/pi/backup_log
fi

if [ "$G" = "y" ]
then
	if [[ -d /home/pi/.ssh ]]
	then
	        echo "SSH folder already exists"
	else
	        echo "Creating SSH folder"
	        mkdir /home/pi/.ssh
	fi

	read -p 'Please enter your GitHub Username: ' USER
	read -p 'Please enter the name of your GitHub repository: ' REPO
	read -p 'Please enter the e-mail of your GitHub account: ' MAIL

	echo "##" >> /home/pi/scripts/klipper_backup_script/backup.cfg
	echo "## GitHub user and repository name" >> /home/pi/scripts/klipper_backup_script/backup.cfg
	echo "USER=$USER" >> /home/pi/scripts/klipper_backup_script/backup.cfg
	echo "REPO=$REPO" >> /home/pi/scripts/klipper_backup_script/backup.cfg

	URL="https://github.com/$USER/$REPO"

	echo ""
	echo "Checking for GitHub SSH key"

	if [[ -f /home/pi/.ssh/github_id_rsa ]]
	then
		echo "SSH key already present"
		echo ""

		ADDED="o"
		while [ "$ADDED" != "y" || "$ADDED" != "n" ]
		do
			read -p 'Did you already add this key to your GitHub account? [y|n] ' ADDED

			case $ADDED in
				n)
					echo "Please add this key to your GitHub account:"
					echo ""
					cat /home/pi/.ssh/github_id_rsa.pub
					echo ""
					echo "You can find instructions for this here:"
				        echo "https://github.com/Low-Frequency/klipper_backup_script"
				        echo ""
					read -p 'Press enter to continue' CONTINUE
					;;
				y)
					echo "Continuing setup"
					;;
				*)
					echo "Please input a valid answer [y|n]"
					;;
			esac
		done
	else
		echo "Generating SSH key pair"
		ssh-keygen -t ed25519 -C "$MAIL" -f /home/pi/.ssh/github_id_rsa -q -N ""
		echo "IdentityFile ~/.ssh/github_id_rsa" >> /home/pi/.ssh/config
		chmod 600 /home/pi/.ssh/config

		echo "Please copy the public key and add it to your GitHub account:"
		echo ""
		cat /home/pi/.ssh/github_id_rsa.pub
		echo ""
		echo "You can find instructions for this here:"
		echo "https://github.com/Low-Frequency/klipper_backup_script"
		echo ""
		read -p 'Press enter to continue' CONTINUE
	fi

	echo ""
	echo "Initializing repo"
	git -C /home/pi/klipper_config init
	git -C /home/pi/klipper_config remote add origin "$URL"
	git -C /home/pi/klipper_config remote set-url origin git@github.com:"$USER"/"$REPO".git

	echo "Setting username"
	git config --global user.email "$MAIL"
	git config --global user.name "$USER"

fi

echo ""

if [ "$C" = "y" ]
then
	echo "Installing rclone"
	curl https://rclone.org/install.sh | sudo bash
	echo ""
	echo "Installing expect"
	sudo apt install expect -y
	echo ""
	echo "Setting up a remote location for your backup"
	REMNAME="google drive"
	while [[ $REMNAME =~ $SPACE ]]
	do
		read -p 'Please name your remote storage (no spaces allowed): ' REMNAME
	done
	echo "##" >> /home/pi/scripts/klipper_backup_script/backup.cfg
	echo "## File paths for cloud backup" >> /home/pi/scripts/klipper_backup_script/backup.cfg
	echo "REMOTE=$REMNAME" >> /home/pi/scripts/klipper_backup_script/backup.cfg
	DIR="some directory"
	echo ""
	while [[ $DIR =~ $SPACE ]]
	do
		read -p 'Please specify a folder to backup into (no spaces allowed): ' DIR
	done
	echo "FOLDER=\"$DIR\"" >> /home/pi/scripts/klipper_backup_script/backup.cfg
	/home/pi/scripts/klipper_backup_script/drive.exp "$REMNAME"
fi

echo ""
echo "Setting up the service"
sudo mv /home/pi/scripts/klipper_backup_script/gitbackup.service /etc/systemd/system/gitbackup.service
sudo chown root:root /etc/systemd/system/gitbackup.service
sudo systemctl enable gitbackup.service
sudo systemctl start gitbackup.service

echo ""

if [ "$G" = "y" ]
then
	echo "Testing SSH connention"
	ssh -T git@github.com
	echo ""
fi

echo "Pushing the first backup to your specified backup location(s)"
/home/pi/scripts/klipper_backup_script/klipper_config_git_backup.sh
rm /home/pi/setup.sh
