import os
import json
import requests
import discord
import random
from discord.ext import tasks, commands
from keep_alive import keep_alive

# ---------- CONFIG ----------
DATA_FILE = "owned_games.json"  # cache file (auto-created)
CHECK_INTERVAL_MIN = 5  # how often to check Steam libraries
# Map "Display Name" to Steam64 ID (fill these in)
STEAM_USERS = {
    "PwhyK": os.environ.get("P"),
    "Timmmot": os.environ.get("T"),
    "Oranjee": os.environ.get("O"),
    "Nico": os.environ.get("N"),
}
# ----------------------------

DISCORD_TOKEN = os.environ.get("DISCORD_TOKEN")
STEAM_API_KEY = os.environ.get("STEAM_API_KEY")
CHANNEL_ID = int(os.environ.get("CHANNEL_ID", "0"))

GAME_THEMED_THANK_YOUS = [
    "🎮 Thanks for leveling up your library!",
    "🕹️ Another epic addition! Thanks!", "⚔️ Thanks for adding a new quest!",
    "🏆 Achievement unlocked: New game! Thanks!",
    "💎 Thanks for collecting another gem!",
    "🎲 Rolling the dice and saying thanks!",
    "🛡️ Thanks for adding some armor to your collection!",
    "🚀 New game acquired! Thanks for sharing!",
    "🔥 Thanks for powering up your library!",
    "🧩 Thanks for completing another puzzle piece!",
    "🌟 Thanks for boosting your gaming stats!",
    "🎯 Another target hit! Thanks!",
    "🗡️ Thanks for sharpening your collection!",
    "🏹 Added a new arrow to your quiver! Thanks!",
    "💣 Boom! New game spotted! Thanks!",
    "🎉 Thanks for expanding your adventure!",
    "⚡ New game unlocked! Thanks for sharing!",
    "🧙‍♂️ Thanks for casting a spell on your library!",
    "🕹️ Another controller-ready game! Thanks!",
    "🏰 Thanks for building your gaming kingdom!"
]

if not DISCORD_TOKEN or not STEAM_API_KEY or CHANNEL_ID == 0:
    raise RuntimeError(
        "Missing env vars. Set DISCORD_TOKEN, STEAM_API_KEY, CHANNEL_ID in Secrets."
    )

if not STEAM_USERS:
    raise RuntimeError(
        "Set STEAM_USERS in main.py to map display names to Steam64 IDs in Secrets."
    )

intents = discord.Intents.default()
bot = commands.Bot(command_prefix="!", intents=intents)


def get_owned_games(steam_id: str) -> dict:
    """
    Returns {appid: name} for a user's library.
    Requires their Steam 'Game details' privacy set to Public.
    """
    url = "https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/"
    params = {
        "key": STEAM_API_KEY,
        "steamid": steam_id,
        "include_appinfo": 1,
        "format": "json"
    }
    try:
        r = requests.get(url, params=params, timeout=20)
        r.raise_for_status()
        data = r.json()
        games = data.get("response", {}).get("games", [])
        return {
            str(g["appid"]): g.get("name", f"App {g['appid']}")
            for g in games
        }
    except Exception as e:
        print(f"[ERROR] get_owned_games({steam_id}): {e}")
        return {}


def load_store() -> dict:
    if os.path.exists(DATA_FILE):
        try:
            with open(DATA_FILE, "r") as f:
                return json.load(f)
        except Exception as e:
            print(f"[WARN] Could not read {DATA_FILE}: {e}")
    return {}


def save_store(store: dict) -> None:
    try:
        with open(DATA_FILE, "w") as f:
            json.dump(store, f)
    except Exception as e:
        print(f"[WARN] Could not write {DATA_FILE}: {e}")


@bot.event
async def on_ready():
    print(f"✅ Logged in as {bot.user}")
    # Kick off the keep-alive web server for Replit
    check_new_games.change_interval(seconds=CHECK_INTERVAL_MIN)
    check_new_games.start()


@tasks.loop(seconds=CHECK_INTERVAL_MIN)
async def check_new_games():
    channel = bot.get_channel(CHANNEL_ID)
    if channel is None:
        print("[ERROR] Channel not found. Check CHANNEL_ID.")
        return

    store = load_store()

    for display_name, steam_id in STEAM_USERS.items():
        new_lib = get_owned_games(steam_id)
        old_lib = store.get(display_name, {})

        # Detect added appids
        added_appids = [aid for aid in new_lib.keys() if aid not in old_lib]
        if added_appids:
            for aid in added_appids:
                game_name = new_lib.get(aid, f"App {aid}")
                thank_you = random.choice(GAME_THEMED_THANK_YOUS)
                try:
                    await channel.send(
                        f"🎉 **{display_name}** just got **{game_name}**!  {thank_you}"
                    )
                except Exception as e:
                    print(f"[ERROR] sending message: {e}")

        # Update store per user
        store[display_name] = new_lib

    save_store(store)


# Start tiny web server to keep Replit awake
keep_alive()

# Run the bot
bot.run(DISCORD_TOKEN)
