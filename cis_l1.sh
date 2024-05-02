cis_lvl_1() {

    echo "Starting CIS Level 1 Baseline compliance for Secure Boot Settings..."

    # Secure Boot Settings
    ## Setting permissions on bootloader configuration
    echo "Securing bootloader configuration..."
    chown root:root /boot/grub/grub.cfg
    chmod og-rwx /boot/grub/grub.cfg

    ## Ensure authentication required for single user mode
    # NOTE: This setting is specific to systems and may need manual configuration.
    # Ubuntu systems with systemd do not have a direct equivalent that requires editing for single user mode.

    ## Ensure bootloader password is set
    # IMPORTANT: Setting a bootloader password should be done manually to ensure security.
    echo "A bootloader password must be set manually to prevent unauthorized changes to boot configuration."

    ## Ensure permissions on EFI partition are configured properly (if system uses EFI)
    EFI_MOUNT=$(findmnt /boot/efi -no TARGET)
    if [ -n "$EFI_MOUNT" ]; then
        echo "Configuring permissions for EFI partition..."
        # Find the UUID of the EFI partition
        EFI_UUID=$(blkid -o value -s UUID ${EFI_MOUNT})
        if [ -n "$EFI_UUID" ]; then
            # Update /etc/fstab with strict permissions for the EFI partition
            echo "UUID=${EFI_UUID} ${EFI_MOUNT} vfat umask=0077 0 1" >> /etc/fstab
            # Remount EFI partition to apply changes
            mount -o remount,umask=0077 ${EFI_MOUNT}
        else
            echo "EFI partition UUID not found. Manual configuration required."
        fi
    else
        echo "EFI partition not found or not used."
    fi

    echo "Secure Boot Settings configuration completed."
    echo "Please remember to manually set a bootloader password to fully comply with CIS Level 1 Baseline."

    # 1.2 Configure Software Updates
    echo "1.2 Configure Software Updates - Ensuring GPG keys are configured for APT repositories..."
    # sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys [KEY_ID]
  	echo "Updating and upgrading system packages"
  	sudo apt update && sudo apt upgrade -y && sudo apt autoremove --purge -y


    # 1.3 Filesystem Integrity Checking
    echo "1.3 Filesystem Integrity Checking - Installing and configuring AIDE..."
    sudo apt-get install aide -y
    sudo aideinit
    sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
    echo "0 5 * * * /usr/bin/aide --check" | sudo tee -a /etc/cron.d/aide-check > /dev/null

     
    # 1.5 Additional Process Hardening
    echo "1.5 Additional Process Hardening - Disabling core dumps..."
    echo '* hard core 0' | sudo tee -a /etc/security/limits.conf > /dev/null
    echo 'fs.suid_dumpable = 0' | sudo tee -a /etc/sysctl.conf > /dev/null
    sudo sysctl -p

    # 1.6 Mandatory Access Control
    echo "1.6 Mandatory Access Control - Enabling and starting AppArmor..."
    sudo systemctl enable apparmor
    sudo systemctl start apparmor

    # 1.7 Warning Banners
    echo "1.7 Warning Banners - Configuring system banners..."
    # Define the security banner with adjusted width
security_banner="
+------------------------------------------------------------------------------+
|                             SECURITY NOTICE                                  |
|                                                                              |
|          ** Unauthorized Access and Usage is Strictly Prohibited **          |
|                                                                              |
|     This computer system is the property of [Company Name].                  |
| All activities on this system are subject to monitoring and recording for    |
| security purposes. Unauthorized access or usage will be investigated and may |
| result in legal consequences.                                                |
|                                                                              |
|      If you are not an authorized user, please disconnect immediately.       |
|                                                                              |
| By accessing this system, you consent to these terms and acknowledge the     |
| importance of computer security.                                             |
|                                                                              |
|            Report any suspicious activity to the IT department.              |
|                                                                              |
|          Thank you for helping us maintain a secure environment.             |
|                                                                              |
|              ** Protecting Our Data, Protecting Our Future **                |
|                                                                              |
+------------------------------------------------------------------------------+
"

# Print the security banner
    echo "$security_banner"
    echo "$security_banner" | sudo tee /etc/issue.net /etc/issue /etc/motd > /dev/null

    # 2. Services
    # 2. Services - SSH Configuration
    echo "2. Services - Hardening SSH..."
    sudo sed -i 's|#Banner none|Banner /etc/issue.net|' /etc/ssh/sshd_config
    sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
    sudo systemctl restart sshd

    echo "2. Services"
    ## 2.1 inetd Services
    echo "2.1 inetd Services..."
    ## 2.2 Special Purpose Services
    echo "2.2 Special Purpose Services..."
    ## 2.3 Service Clients
    echo "2.3 Service Clients..."



    # 4. Logging and Auditing - Audit Configuration
    echo "4. Logging and Auditing - Configuring auditd..."
    sudo apt-get install auditd -y
    sudo systemctl enable auditd
    sudo systemctl start auditd
    echo "-w /var/log/faillog -p wa -k auth" | sudo tee -a /etc/audit/rules.d/audit.rules > /dev/null
    echo "-w /var/log/auth.log -p wa -k auth" | sudo tee -a /etc/audit/rules.d/audit.rules > /dev/null
    sudo systemctl restart auditd    

    # 5. Access, Authentication, and Authorization - User and Group Settings
    echo "5. Access, Authentication, and Authorization - Configuring user and group settings..."
    sudo chown root:root /etc/passwd /etc/shadow /etc/group /etc/gshadow
    sudo chmod 644 /etc/passwd /etc/group
    sudo chmod 640 /etc/shadow /etc/gshadow

    # 5.1 Configure cron and at
    echo "5.1 Configure cron and at - Securing cron jobs..."
    sudo chmod 0600 /etc/crontab
    sudo chmod 0700 /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.d

    # 5.2 SSH Server Configuration
    echo "5.2 SSH Server Configuration - Further SSH hardening..."
    sudo chown root:root /etc/ssh/ssh_host_*
    sudo chmod 600 /etc/ssh/ssh_host_*

    # 5.3 Configure Authentication and Authorization
    echo "5.3 Configure Authentication and Authorization - Configuring password policies and PAM..."
    sudo apt install libpam-pwquality -y
    sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
    sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/' /etc/login.defs
    sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 14/' /etc/login.defs
    echo "password requisite pam_pwquality.so retry=3 minlen=14 difok=4" | sudo tee -a /etc/pam.d/common-password > /dev/null

    # 6. System Maintenance - System File Permissions
    echo "6. System Maintenance - Ensuring system file permissions are properly set..."
    sudo find /var/log -type f -exec chmod g-wx,o-rwx {} +

    # 7. Network Configuration and Firewalls
    echo "7. Network Configuration and Firewalls - Setting up firewall and hardening network..."
    sudo apt install ufw -y
    sudo ufw enable

    echo "CIS Level 1 compliance settings applied. Review and customize further as needed."
}
