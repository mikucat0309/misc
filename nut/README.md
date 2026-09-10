# Network UPS Tools Container

## Usage

```sh
docker run --name nut -d \
--restart always --privileged \
-v /dev/bus/usb:/dev/bus/usb \
-v /run/systemd/private:/run/systemd/private \
ghcr.io/mikucat0309/nut:latest
```
