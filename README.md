# MacBook Accordion

MacBook Accordion turns the lid angle sensor in newer MacBooks into a tiny
accordion-style instrument.

Move the lid to choose a note, then hold Space to let the reeds sound. Releasing
Space mutes the audio, so you can silently move through notes and only play the
ones you want.

This is a personal fork of Sam Gold's original lid angle sensor experiment:
https://github.com/samhenrigold/LidAngleSensor

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

## Building

Open `MacBookAccordion.xcodeproj` in Xcode and build the `MacBookAccordion`
target.

This local checkout has also been verified with Swift typechecking from the
command line:

```shell
rg --files -g '*.swift' | xargs swiftc -typecheck -swift-version 6 -default-isolation MainActor -target arm64-apple-macosx14.0
```
