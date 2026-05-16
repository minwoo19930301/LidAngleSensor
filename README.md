# MacBook Accordion

![A person holding a MacBook like an accordion while covering the camera area.](assets/macbook-accordion-usage.png)

MacBook Accordion turns the lid angle sensor in newer MacBooks into a tiny
accordion-style instrument.

Cover the camera area, then open and close the MacBook lid like bellows. The lid
angle chooses the note, and the ambient light sensor works like the air button:
covering the camera area alone is silent, and a note only plays when the lid
crosses into a different note while the sensor is covered.

This is a personal fork of Sam Gold's original lid angle sensor experiment:
https://github.com/samhenrigold/LidAngleSensor

## Install

The easiest install path is the hosted DMG on GitHub Releases:

1. Open the [latest release](https://github.com/minwoo19930301/macbook-accordion/releases/latest).
2. Download `MacBookAccordion-0.1.2.dmg`.
3. Open the DMG.
4. Drag `MacBook Accordion.app` into `Applications`.
5. Quit any older copy of the app, then launch `MacBook Accordion`.

This is a personal unsigned build. If macOS blocks the first launch, Control-click
`MacBook Accordion.app`, choose `Open`, then confirm once. After that it should
open normally.

## How To Play

1. Open `MacBook Accordion`.
2. Cover the camera area with a finger or tape.
3. While covering it, grip the keyboard body and display with both hands.
4. Open and close the lid sideways like an accordion.
5. Uncover the camera area whenever you want to move silently without playing a
   note.

There is no Play button. The app is always ready, but covering the camera area
only arms the next note change. The app reads the ambient light sensor's lux
value, not camera video, so this works while another app is focused and does not
need camera or keyboard permissions.

## Features

- Lid angle selects stepped notes.
- Covering the camera area acts like an air button and does not play by itself.
- Lid motion adds bellows expression.
- Detuned reed oscillators and tremolo create the accordion tone.
- Tone controls adjust cover threshold, air pressure, detune, brightness, bass
  mix, and tremolo.

## Compatibility

The underlying sensor was introduced with the 2019 16-inch MacBook Pro. Newer
MacBooks are more likely to work, though some M1/M2 models have known issues in
the upstream project.

Desktop Macs and older MacBooks without the lid angle sensor cannot play this
instrument.

## Build From Source

Use this if you want to customize the app.

```shell
git clone https://github.com/minwoo19930301/macbook-accordion.git
cd macbook-accordion
open MacBookAccordion.xcodeproj
```

Then build the `MacBookAccordion` target in Xcode.

You can also create a local universal DMG from the command line:

```shell
./scripts/package_dmg.sh 0.1.2
```

The DMG will be written to `dist/MacBookAccordion-0.1.2.dmg`.

This local checkout has also been verified with Swift typechecking:

```shell
rg --files -g '*.swift' | xargs swiftc -typecheck -swift-version 6 -default-isolation MainActor -target arm64-apple-macosx14.0
```
