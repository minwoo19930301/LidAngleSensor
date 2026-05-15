# MacBook Accordion

![A person holding a MacBook like an accordion, pressing Space while opening and closing the lid.](assets/macbook-accordion-usage.png)

MacBook Accordion turns the lid angle sensor in newer MacBooks into a tiny
accordion-style instrument.

Hold Space, then open and close the MacBook lid like bellows. The lid angle
chooses the note, and Space works like the air button: release Space to mute,
move silently to another note, then hold Space again to play.

This is a personal fork of Sam Gold's original lid angle sensor experiment:
https://github.com/samhenrigold/LidAngleSensor

## Install

The easiest install path is the hosted DMG on GitHub Releases:

1. Open the [latest release](https://github.com/minwoo19930301/macbook-accordion/releases/latest).
2. Download `MacBookAccordion-0.1.0.dmg`.
3. Open the DMG.
4. Drag `MacBook Accordion.app` into `Applications`.
5. Launch `MacBook Accordion`.

This is a personal unsigned build. If macOS blocks the first launch, Control-click
`MacBook Accordion.app`, choose `Open`, then confirm once. After that it should
open normally.

## How To Play

1. Open `MacBook Accordion`.
2. Hold the Space bar.
3. While holding Space, grip the keyboard body and display with both hands.
4. Open and close the lid sideways like an accordion.
5. Release Space whenever you want to move silently without playing a note.

There is no Play button. The app is always ready; Space decides when sound comes
out.

## Features

- Lid angle selects stepped notes.
- Space acts like an air button.
- Lid motion adds bellows expression.
- Detuned reed oscillators and tremolo create the accordion tone.
- Tone controls adjust air pressure, detune, brightness, bass mix, and tremolo.

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
./scripts/package_dmg.sh 0.1.0
```

The DMG will be written to `dist/MacBookAccordion-0.1.0.dmg`.

This local checkout has also been verified with Swift typechecking:

```shell
rg --files -g '*.swift' | xargs swiftc -typecheck -swift-version 6 -default-isolation MainActor -target arm64-apple-macosx14.0
```
