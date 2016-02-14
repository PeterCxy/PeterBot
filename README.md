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
