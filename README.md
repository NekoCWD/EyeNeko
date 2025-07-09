# EyeNeko

Customizable gstreamer-based camera

Mostly made for PostmarketOS phones

## Environment variables:
  - `CAM_N` = `0` - Int, camera number
  - `CAM_M` = `photo` - String, camera mod `video` or `photo`
  - `DOWNSCALE_VIDEO` = `640` - Int, maximum image dimension in video mode (0 to disable downscale)
  - `DOWNSCALE_PHOTO` = `0` - Int, maximum image dimension in photo mode (0 to disable downscale)
  - `VIDEO_ENCODE` = `x264enc tune=zerolatency speed-preset=ultrafast bitrate=8192` - String, video encode pipeline
  - `AUDIO_ENABLED` = `true` - Bool, is audio record enabled (`false` to disable)
  - `AUDIO_PROFILE` = `audio/x-ac3` - String - audio encoding
  - `CAM_CAPS` = auto max caps by default - String
  - `ONLY_FORMAT` = null - String, filter pixel formats to show only one (e.g `RGB`)
  - `CAM_PROVIDER` = `pipewiredeviceprovider` - String, camera provider name (e.g `libcameraprovider`)
  - `ROTATE` = `0` - Int, Rotation

## Project TODO:
  - [ ] Fix cam/mode switching? (I can't reproduce errors)
  - [ ] Simplify customization
    - [ ] Transform environment variables to nice UI
    - [ ] Fix ColorCorrection hardcode
      - [ ] Add ColorCorrection setting (UI)
  - [ ] Add per-camera customization
  - [ ] Add ability to make settings json import/export
  - [ ] Add image pipeline customization
  - [ ] Add image/video container customization
  - [ ] Add image/video encoding customization
  - [ ] Add ability to disable sound capture
  - [ ] Add ability to rotate image
