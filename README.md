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
        { "name": "2700º", "display": 2700, "hue": 2000 },
        { "name": "3500º", "display": 3500, "hue": 2400 },
        { "name": "4500º", "display": 4500, "hue": 2700 },
        { "name": "5500º", "display": 5500, "hue": 3350 },
        { "name": "6500º", "display": null, "hue": 4000 }
    ]
}
```

5. Repeat step 2 and click "Reload Settings".
