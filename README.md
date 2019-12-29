# rootlessJB12.4

[App](https://github.com//BrandonPlank/rootlessJB4/blob/master/IMG_0486.png?raw=true)

## Support

- All A7-A11 devices
- iOS 12.0 - 12.2 & 12.4

# One Week Uptime Check Point
![AIDA64](https://github.com//BrandonPlank/rootlessJB4/blob/master/IMG_545942B67DA6-1.JPEG?raw=true)

## Saily Package Manager
- Saily.Daemon is bundled with rootlessJB4
- The SailySandBoxed.ipa should be installed as well as rootlessJB4.ipa
- Not all packages work with our patches. Wait for developers to update

## Usage notes

- Binaries are located in: /var/containers/Bundle/iosbinpack64
- Jailbreak structs can be found at /var/containers/Bundle/tweaksuppoet/
- Symlinks include: /var/LIB, /var/ulb, /var/bin, /var/sbin, /var/Apps, /var/libexec
- Root file system will be kept read only, just don't mess /var and you will be safe.

## So what those scripts do?

- unSign.sh keeps Apple away from tracing our expensive certs.
- unPack, Clean, Pack are used for those binpacks.

## What's next?
- fixmMap is coming for App Store apps.
- Adding support for remounting the user filesystem, but nothing will be wrote to /. So unless you put Cydia.app in /Applications you should be fine. You can also disable it.
- Full Substituite
- New Tweak Inject(Current one causes the device to kernel panic when installing a tweak from Saily)
- A12 support for iOS 12?

## Future.
- I plan to maintain rootlessJB4 for as long as jailbreaking is alive. I could not have made a more stable (and safe) Jailbreak without Lakr, John, and Chr0nic! It saddens me that at this point in time rootlessJB4 is the ONLY currently open sourced project. (besides unc0ver which is now closed source for any new update.) I plan to let people learn and continue making jailbreaks. Therefore this will always be maintained and OPEN SOURCED!

Thanks to: 

* Ian Beer
* Brandon Azad
* Brandon Plank
* Jonathan Levin
* IBSparkes
* Sam Bingner
* Sammy Guichelaar
* Ned Williamson
* Umang Raghuvanshi
* Tanay Findley
* Lakr Aream
