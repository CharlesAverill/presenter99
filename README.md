# Presenter99

Presenter99 is a slideshow engine written in BASIC for the [TI-99/4A](https://en.wikipedia.org/wiki/TI-99/4A).

![example slideshow](media/presenter99.gif)

## Usage

Slideshows are encoded in the engine program as `DATA` commands between lines 1-1899.
Simply edit [template.bas](src/template.bas) and run `make` to generate [presenter99.bas](src/presenter99.bas).
This program can be copied into an emulator such as Classic99.
Exporting to WAV files for cassette storage is planned.

### Format

A slideshow is encoded as a series of *events*.
Each event consists of an *opcode* and a list of arguments.

The first event is always `TITLE`, which sets the presentation's title, subtitle, and default foreground and background colors:

```basic
10 DATA "TITLE","My Presentation","Charles Averill",16,2
```

This data will be rendered as a title slide.

The remainder of the slideshow consists of slides, delimited by `SLIDE` events.
Each `SLIDE` event denotes a new slide with a given title:

```basic
20 DATA "SLIDE","Slide 1"
```

Within each slide can be any number of events.
A table of their effects is provided below.

| Event | Effect | Example |
|---|---|---|
| `TEXT` | Draw left-aligned text that may wrap around the screen | `30 DATA "TEXT","Here is some text"` |
| `LIST` | Draw an unordered list | `40 DATA "LIST","First","Second","Third","END"` |
| `SPACING` | Print `N` empty lines if `N>=0`, or print until the screen is almost full (for printing footers) if `N=-1` | `100 DATA "SPACING",-1` |
| `COLORS` | Update the foreground and background colors, will take effect on slide transition | `50 DATA "COLORS",5,16` |
| `PAUSE` | Pause in the middle of a slide | `95 DATA "PAUSE"` |
