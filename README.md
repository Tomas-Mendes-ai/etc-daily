# /etc/daily

Backup of the configs, packages, dotfiles, etc., I'm using on my daily driver.  
Made it public for the curious/anyone who may find it useful.

### (Relevant) system info

OS: Arch Linux  
RAM: 16GB DDR4  
CPU: AMD RYZEN 5 5600H  
dGPU: NVIDIA RTX 3050 Mobile  
Storage: 256GB NVMe SSD + 256GB SATA SSD  

### Partitioning

- Full Disk Encryption using Luks.
- /efi partition for the bootloader and the Unified Kernel Images.
- Notabily, no boot partition since UKI's (sort of) deprecate the need for two partitions.
- Swap partition with 16GiB to suport hibernation.  
  
### Decryption  

- /etc/cmdline.d/* /etc/mkinitcpio.conf.d/* /etc/mkinitcpio.d/* /etc/crypttab*
- Required services included in initramfs using mkinitcpio hooks,
- Systemd-cryptsetup handles decryption at boot.
- Decryption of / and swap is password-based. Kernel caching in RAM ensures only one password-prompt is needed.
- Will upgrade to a TPM-enrolled keyfile.
  
### Secure Boot  

- WIP
- In the processes of making my PKI.
- Will then enroll the PK, KEK, and db certificates in the firmware.
- Will probably use systemd-ukify to automatically sign the UKIs after it builds them.
  
### DNS  

- /etc/systemd/resolved.conf.d/*
- Configured systemd-resolvd's stub (@127.0.0.53) to use DoT.
- As of now any new connection must have its DHCP and DNS edited to use the stub.
  
### Kernel Parameters  

- /etc/sysctl.d/*
- Mostly related to network security and security in general
  
### SSHD  

- /etc/ssh/sshd_config.d/*
- Set several configs to harden ssh access
  
### PAM  

- /etc/security/access.d/* /etc/pam.d/*
- Root can only login locally
- My user can login from anywhere
- All others logins are explicitly disabled
- Only users in group wheel can use 'su' and 'su -l'
  
### Firewall  

- WIP
  
### Todo:  

- Finish this readme by explaining the rest of the configs.
- Setup secure boot
- Use the tpm for decryption and measured boot
- Probably want to install hyprland for work flows and leave plasma just for gaming (unless hyprland handles that well)
