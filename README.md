Peter's Telegram Bot
---
To get started, create `config.json` in the cloned directory

```json
{
  "token": "your bot's token",
  "modules": [
    "module1",
    "module2",
    ...
  ]
}
```

Modules are placed in `src/modules`. Add them to the config file without the suffix `.coffee` will make the bot load them on starting.

Before starting the bot, you need to run `npm install` in this directory. Then, just run `npm start` to start the bot.

__This bot is written in Literate CoffeeScript, so further information is available in the source code. See litcoffee files in src directory for more details on configuration and the program.__

License
---
This program is written in `Literate CoffeeScript`, which is made up of two parts: the document and the source code inside the document.

The source code is licensed under GNU General Public License version 3. <http://www.gnu.org/licenses/gpl-3.0.en.html>

The document is licensed under CC Attribution-ShareAlike 4.0 International. <https://creativecommons.org/licenses/by-sa/4.0/>
