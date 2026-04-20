# Lenovo Yoga 7i

## GPU codecs

Intel integrated graphics. See [INTEL_GPU_CODECS.md](./INTEL_GPU_CODECS.md).

## Audio

Default SOF config leaves the bass speakers dead. Override with the `alc287-yoga9-bass-spk-pin` model hint:

```bash
echo "options snd-sof-intel-hda-generic hda_model=alc287-yoga9-bass-spk-pin" | sudo tee /etc/modprobe.d/yoga7i-audio.conf
systemctl reboot
```
