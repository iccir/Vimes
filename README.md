# Vimes

Vimes is a macOS menu bar app to control both
[Apple Night Shift](https://support.apple.com/en-us/HT207513) and
 [Philips Hue](http://meethue.com).

## Why?

I wanted to adjust the white point of both my monitor and my room with a single slider.

## Setup

1. Compile and launch Vimes.
2. Hold down Option, click the icon in the menu bar, click "Reveal Settings".
4. Edit the resulting `settings.json` file. Set `hue-url` to a group endpoint. For example:

```
{
    "hue-url": "http://192.168.1.34/api/362eferOUScgAaFb02afa2fca757ae4024e095b2c/groups/1/action",
    
    "presets": [
        { "name": "2700º", "cct": 2700, "hue": 2000 },
        { "name": "3500º", "cct": 3500, "hue": 2400 },
        { "name": "4500º", "cct": 4500, "hue": 2700 },
        { "name": "5500º", "cct": 5500, "hue": 3350 },
        { "name": "6500º", "cct": null, "hue": 4000 }
    ]
}
```

5. Repeat step 2 and click "Reload Settings".

## Settings File

Top level object:

| Name    | Type   | Description
|---------|--------|---
| hue-url | String | The URL for the Philips Hue group endpoint
| presets | Array  | An array of preset objects

Preset objects:

| Name | Type   | Description
|------|--------|---
| name | String | The name of the preset -- displayed under the slider.
| xy   | Array  | If specified, `CoreDisplay_SetWhitePointWithDuration` is called with the xy values after Night Shift is set. This allows Vimes to use color temperatures under 2700º.
| cct  | Number | The color temperature (in ºK) sent to Night Shift. If `null`, Night Shift is disabled.
| hue  | Number | The color temperature (in ºK) sent to Philips Hue. If `null`, nothing is sent to Philips Hue.
