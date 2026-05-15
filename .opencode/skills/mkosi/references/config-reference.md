# mkosi Configuration Reference

Config files use standard INI format. All config is in `mkosi.conf` (or `mkosi/mkosi.conf`) with drop-ins in `mkosi.conf.d/*.conf`.

---

## [Match] / [TriggerMatch] / [Assert] / [TriggerAssert]

Conditional includes. [Match] uses AND semantics (all must match). [TriggerMatch] uses OR (any can match). [Assert]/[TriggerAssert] fail if conditions not met.

**Available match keys:**

| Key | Values |
|-----|--------|
| `Distribution=` | fedora, debian, ubuntu, arch, opensuse, mageia, centos, rhel, rocky, alma, azure, postmarketos, custom |
| `Release=` | e.g., 41, 40, "trixie", "noble" |
| `Architecture=` | x86-64, aarch64, arm, riscv64, s390x, loongarch64, parisc, ppc64le |
| `Format=` | directory, tar, cpio, disk, esp, uki, oci, sysext, confext, portable, addon, none |
| `Profile=` | Profile name |
| `ImageVersion=` | Semver range |
| `Hostname=` | Hostname match |
| `KernelCommandLine=` | Kernel cmdline match |
| `SecureBoot=` | yes, no |
| `TPM=` | yes, no |
| `SectorSize=` | 512, 4096, auto |
| `QemuDrives=` | Number of extra drives |
| `BootProtocols=` | uefi, bios |
| `ImageId=` | Image name match |
| `HostDistro=` | Host distro match |
| `HostArch=` | Host arch match |
| `HostRelease=` | Host release match |
| `HostOS=` | Host OS name match |
| `HostCIBelongsTo=` | CI system match |
| `PathExists=` | File path that must exist |

---

## [Config]

| Key | Description |
|-----|-------------|
| `Profiles=` | Space-separated list of profiles to activate |
| `Dependencies=` | Space-separated list of subimage dependencies (build order) |
| `MinimumVersion=` | Minimum mkosi version required |
| `ConfigureScripts=` | Executables that receive/set config as JSON |

---

## [Distribution]

| Key | Description |
|-----|-------------|
| `Distribution=` | Target distribution |
| `Release=` | Release version/name |
| `Architecture=` | Target architecture |
| `Mirror=` | Package manager mirror URL |
| `LocalMirror=` | Local-only mirror (not written to image) |
| `Repositories=` | Additional repositories to enable |
| `RepositoryKeyCheck=` | Verify repository GPG keys (default: yes) |
| `RepositoryKeyFetch=` | Fetch missing GPG keys (default: no, security-sensitive) |
| `SshCA=` | SSH CA certificate path |
| `SshClientCertificate=` | SSH client certificate |
| `SshServerCertificate=` | SSH server certificate |
| `Snapshot=` | Snapshot date/version for reproducible builds |
| `Architecture=` | Override architecture for package manager |

---

## [Output]

| Key | Description |
|-----|-------------|
| `Format=` | Output format (see formats above) |
| `Output=` | Output filename |
| `OutputDirectory=` | Directory for output files |
| `ImageVersion=` | Image version string (overrides mkosi.version) |
| `ImageId=` | Image name/identifier |
| `Compression=` | Compression: zstd, xz, gzip, none |
| `CompressionLevel=` | Compression level (1-22, nodefaults) |
| `CompressionThreads=` | Compression threads (auto) |
| `SplitArtifacts=` | Split UKI/kernel/initrd into separate outputs: yes, no |
| `RepartDirectories=` | Extra directories for repart definitions |
| `MakeInitrd=` | Build as initrd (Format=cpio): yes, no |
| `TarStripSELinuxContexts=` | Strip SELinux contexts in tar output |
| `TarStripMounts=` | Strip mount points in tar output |

---

## [Content]

| Key | Description |
|-----|-------------|
| `Packages=` | Packages to install in image |
| `BuildPackages=` | Packages only available during build scripts |
| `PackagesDirectory=` | Directory with extra RPMs/debs |
| `BuildPackagesDirectory=` | Extra packages for build overlay |
| `ExcludePackages=` | Packages to exclude |
| `CleanupPackages=` | Packages removed before final image |
| `WithDocs=` | Include documentation: yes, no, never, default |
| `WithTests=` | Run tests during build: yes, no, never |
| `CacheOnly=` | Only use package cache, don't fetch: yes, no |
| `ReadOnly=` | Make rootfs read-only: yes, no |
| `MinimizeSize=` | Minimize image size (removes unneeded files): yes, no |
| `MinimizeSizeThreshold=` | Free space ratio threshold for minimization (default: 0.8) |
| `Acl=` | Build overlay uses ACLs for permissions: yes, no |
| `UseSubvolumes=` | Use btrfs subvolumes: yes, no |
| `Repart=` | Use systemd-repart for disk images: yes, no |
| `RepartOffline=` | Use offline repart mode: yes, no |
| `BaseTrees=` | Base OS trees to overlay |
| `SkeletonTrees=` | Directories copied before package install (mkosi.skeleton/) |
| `ExtraTrees=` | Directories copied after package install (mkosi.extra/) |
| `CleanScripts=` | Scripts run on `mkosi clean` |
| `PrepareScripts=` | Scripts run inside image before caching |
| `BuildScripts=` | Scripts run in build overlay with build deps |
| `PostInstallationScripts=` | Scripts after packages installed |
| `FinalizeScripts=` | Scripts on staging directory (outside image) |
| `PostOutputScripts=` | Scripts after final image assembled |
| `Script=` | Generic script alias (auto-assigns to appropriate phase) |
| `Environment=` | Environment variables for scripts |
| `EnvironmentFile=` | File with env vars for scripts |
| `WithNetwork=` | Network access during build: yes, no |
| `Cache=/dev/shm` | Cache directory for package manager |
| `CleanupCopyPackages=` | additional package cleanup |
| `KernelCommandLine=` | Kernel command line arguments |
| `KernelCommandLineExtra=` | Extra kernel cmdline (appended) |
| `KernelModulesInitrd=` | Additional kernel modules for initrd |
| `KernelModulesInclude=` | Glob patterns for kernel modules to include |
| `KernelModulesExclude=` | Glob patterns for kernel modules to exclude |
| `KernelModulesInitrdInclude=` | Initrd-specific module include patterns |
| `KernelModulesInitrdExclude=` | Initrd-specific module exclude patterns |
| `Bootable=` | Make image bootable: yes, no, auto |
| `Bootloader=` | Bootloader: systemd-boot, uki, grub, systemd-boot-signed, grub-signed, uki-signed |
| `BiosBootloader=` | BIOS bootloader: grub |
| `ShimBootloader=` | Shim for UEFI secure boot: unsigned, signed |
| `UnifiedKernelImages=` | Use UKI instead of Type 1: yes, no, auto |
| `UefiSecureBoot=` | Enable SecureBoot: yes, no |
| `UefiSecureBootAutoEnroll=` | Auto-enroll SecureBoot keys: yes, no |
| `UefiSecureBootCertificate=` | Certificate file path |
| `UefiSecureBootKey=` | Private key file path |
| `UefiSecureBootSignTool=` | Signing tool: pesign, sbsigntool |
| `PCRs=` | TPM PCRs to measure/sign |
| `SignExpectedPCR=` | Embed expected PCR values in UKI: yes, no |
| `TPM=` | Enable TPM device: yes, no |
| `TPM2EventLog=` | Include TPM2 event log: yes, no |
| `Verity=` | Use dm-verity: yes, no |
| `VerityData=` | Include verity hash data: yes, no |
| `VerityPartitions=` | Partitions to protect with verity |
| `Usr=yes` | Separate /usr partition: yes, no |
| `Home=` | Home partition: yes, no |
| `Servicable=` | Home partition: yes, no |
| `Swap=` | Swap partition: yes, no |
| `Root=` | /root directory: yes, no |
| `Tmp=` | /tmp directory: yes, no |
| `Var=` | /var directory: yes, no |
| `Srv=` | /srv directory: yes, no |
| `RootSize=` | Root partition size (e.g., "10G") |
| `RootMax=` | Root partition maximum size |
| `RootMin=` | Root partition minimum size |
| `HomeSize=` | /home partition size |
| `HomeMax=` | /home partition maximum |
| `HomeMin=` | /home partition minimum |
| `SrvSize=` | /srv partition size |
| `SwapSize=` | Swap partition size |
| `OutputSplitRoot=` | Split root partition to separate file: yes, no |
| `OutputSplitVerity=` | Split verity to separate file: yes, no |
| `OutputSplitKernel=` | Split kernel/UKI to separate file: yes, no |
| `OutputSplitEss=` | split ESP to separate file: yes, no |
| `SectorSize=` | Disk sector size: 512, 4096, auto |
| `DiskSequential=` | Prefer sequential I/O on disk: yes, no |
| `DiskGenerateUUID=` | Generate partition UUIDs (don't use seed): yes, no |
| `DiskGptFirstLBA=` | First LBA for GPT header |
| `DiskGuid=` | Disk GUID |
| `Encrypt=` | Encrypt partitions: key, tpm2, tpm2-key, tpm2-pin |
| `Passphrase=` | Passphrase file for encryption |
| `ReadOnly=` | Read-only root: yes, no |
| `GrowFileSystems=` | Auto-grow filesystems: yes, no |
| `Fsck=` | Run fsck: yes, no |
| `QemuDrives=` | Number of extra VM drives |
| `QemuDriveSize=` | Size of extra VM drives |
| `InitrdPackages=` | Packages for the default initrd |
| `InitrdProfiles=` | Initrd profiles: lvm, network, nfs, pkcs11, plymouth, raid |
| `InitrdUefiStub=` | UEFI stub for UKI |
| `InitrdUefiStubSource=` | Source for UEFI stub |
| `Initrd=` | Custom initrd image/configuration |
| `MakeInitrd=` | Build initrd-style image |
| `Microcode=` | Include CPU microcode: yes, no, auto |
| `Locale=` | System locale |
| `LocaleMessages=` | Message locale |
| `Keymap=` | Keyboard layout |
| `Timezone=` | System timezone |
| `Hostname=` | System hostname |
| `RootPassword=` | Root password (or executable producing it) |
| `RootHome=` | Root home directory |
| `Password=` | Additional user passwords |
| `Autologin=` | Enable root autologin: yes, no |
| `AddPassword=` | Additional password entries |
| `KernelInitrd=` | Kernel initrd type |
| `MachineID=` | Machine ID (or "auto") |
| `Seed=` | Build seed for reproducibility |
| `SourceDateEpoch=` | SOURCE_DATE_EPOCH timestamp |
| `ImageVersion=` | Image version tag |
| `ImageId=` | Image identifier |

---

## [Validation]

| Key | Description |
|-----|-------------|
| `Checksum=` | Generate SHA256SUMS: yes, no |
| `Sign=` | GPG-sign checksums: yes, no |
| `Key=` | GPG key for signing |
| `Certificate=` | GPG certificate |
| `Passphrase=` | GPG passphrase file |
| `UefiSecureBoot=` | SecureBoot: yes, no |
| `UefiSecureBootCertificate=` | Cert path |
| `UefiSecureBootKey=` | Key path |
| `UefiSecureBootSignTool=` | Signing tool: pesign, sbsigntool |
| `UefiSecureBootAutoEnroll=` | Auto-enroll: yes, no |
| `Verity=` | dm-verity: yes, no |
| `VerityData=` | Verity hash data: yes, no |
| `SignExpectedPCR=` | Embed PCR sigs in UKI: yes, no |
| `PCRs=` | TPM PCRs for measurement |

---

## [Build]

| Key | Description |
|-----|-------------|
| `ToolsTree=` | Tools tree config: tools, ToolsTree config directory, `no` |
| `ToolsTreeDistribution=` | Distro for tools tree |
| `ToolsTreeRelease=` | Release for tools tree |
| `ToolsTreePackages=` | Extra packages in tools tree |
| `BuildDirectory=` | Build overlay directory |
| `CacheDirectory=` | Package cache directory |
| `Incremental=` | Incremental builds: yes, no |
| `BuildSources=` | Build source directories |
| `BuildSourcesEphemeral=` | Use ephemeral copies of build sources: yes, no |
| `SandboxTrees=` | Directories available in sandbox |
| `Environment=` | Build environment variables |
| `EnvironmentFile=` | Env file for build |
| `WithNetwork=` | Network during build: yes, no |
| `Cache=` | Additional caches |
| `Proxy=` | HTTP proxy URL |
| `ProxyCA=` | Proxy CA certificate |
| `ProxyClientCertificate=` | Proxy client cert |
| `ProxyPeerCertificate=` | Proxy peer cert |

---

## [Runtime]

| Key | Description |
|-----|-------------|
| `VM=` | VM backend: qemu, vmspawn |
| `Firmware=` | Firmware type: auto, bios, uefi, uefi-secure, linux |
| `Console=` | VM console: gui, gfx, tty, native |
| `RAM=` | VM RAM size |
| `RAMMax=` | VM maximum RAM |
| `CPUs=` | VM CPU count |
| `CPUMax=` | VM maximum CPUs |
| `VSock=` | Enable vsock: yes, no |
| `VSockCID=` | vsock CID |
| `Network=` | Network backend: user, tap, bridge, direct, vlan |
| `Tap=` | TAP interface name |
| `Bridge=` | Bridge interface name |
| `MAC=` | VM MAC address |
| `TPM=` | Expose TPM to VM: yes, no |
| `TPM2EventLog=` | TPM2 event log: yes, no |
| `CDRom=` | CD-ROM image |
| `Drives=` | Extra VM drives |
| `DriveSize=` | Extra drive size |
| `Kernel=` | Kernel image for VM |
| `KernelCommandLine=` | Extra cmdline for VM |
| `Initrd=` | Initrd for VM |
| `NSpawnSettings=` | systemd-nspawn settings file |
| `Ssh=` | Enable SSH in image: yes, no |
| `SshPort=` | Host SSH port |
| `SshKey=` | SSH key for auth |
| `SshAgent=` | SSH agent socket |
| `SshTimeout=` | SSH connection timeout |
| `RuntimeDirectories=` | Directories created at boot |
| `RuntimeBuildSources=` | Build sources at boot |
| `RuntimeNetwork=` | Network at boot |
| `RuntimeSize=` | Runtime partition size |
| `RuntimeTrees=` | Runtime trees |
| `QemuKernels=` | Additional QEMU kernels |
| `Audio=` | VM audio: yes, no |
| `Vsock=` | VSOCK: yes, no |
| `Kvm=` | KVM acceleration: yes, no |
| `Shm=` | Shared memory size |
| `Virtiofs=` | Use virtiofs for shared dirs |
| `9p=` | Use 9p for shared dirs |
