# Golden Helix App Streaming Core Images

This repository contains the base or **"Core"** images from which all other App Streaming images are derived.


```
./build.sh
```

```
docker run --rm   -e IDLE_TIMEOUT=900   --shm-size="1gb"   -e VNC_PW=password   -p 6901:6901   registry.goldenhelix.com/public/ghdesktop-core:x86_64-debian-bookworm-<date>
```

The container is now accessible via a browser : `https://<IP>:6901`

 - **User** : `ghuser`
 - **Password**: `password`


## Building

Before running ./build.sh, prepare the KasmVNC debian package and copy into src/kasmvncserver.deb

```
cd  ../KasmVNC #Checked out from git@github.com:goldenhelix/KasmVNC.git
./builder/build-package debian bookworm
# To fix  permission issue
cp /tmp/kasmvnc.debian_bookworm.tar.gz builder/build/
./builder/build-deb debian bookworm
cp builder/build/bookworm/kasmvncserver_1.3.2-1_amd64.deb ../appstream-core-images/src/kasmvncserver.deb
```
