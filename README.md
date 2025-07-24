# /etc/daily

Backup of the configs etc., I'm using on my daily driver.  
Made it public for the curious/anyone who may find it useful.

## (Relevant) system info

OS: Arch Linux  
RAM: 16GB DDR4  
CPU: AMD RYZEN 5 5600H  
dGPU: NVIDIA RTX 3050 Mobile  
Storage: 256GB NVMe SSD + 256GB SATA SSD  

## Partitioning

- Full Disk Encryption using Luks.
- /efi partition for the bootloader and the Unified Kernel Images.
- notabily, no boot partition since UKI's (sort of) deprecate the need for two partitions.
- swap partition with 16GiB so I can hibernate.
- one 120GiB btrfs partition for snapshots and backups (might be small, hope compression handles it)  .
- two btrfs partition using raid0 for data and raid1 for metadata as a root partition.

## Decryption

- mkinitcpio configured to include the proper services in the initramfs.
- systemd-cryptsetup handles decryption.
- currently queries for the decryption key on boot. Thankfully the key is cached by the kernel and it's only required to be typed once.
- Will upgrade to a keyfile-based flow and enroll it in the TPM protected by PCRs and a PIN

## Secure Boot

- WIP
- In the processes of making my PKI.
- Will then enroll the PK, KEK, and db certificates in the firmware.
- Will probably use systemd-ukify to automatically sign the UKIs after it builds them.

## DNS

- Configured systemd-resolvd's stub (@127.0.0.53) to use DoT.
- Right now I have to edit any connection to only use DHCP for addresses and manually configure the DNS to point to the stub.
- Would very much appreciate NetworkManager just doing that automatically for every new connection but no luck finding that config yet.

## Todo:

- Finish this readme by explaining the rest of the configs.
- Setup secure boot
- Use the tpm for decryption and measured boot
- Probably want to install hyprland for work flows and leave plasma just for gaming (unless hyprland handles that well)