/**
 * Role → card image filename map, copied VERBATIM from the production game.html
 * (getRoleCardPath + CARD_MAP_EN + CARD_MAP_DE_EXCEPTIONS). Vanilla untouched.
 * Cards live at /assets/cards/{de,en}/<file>.webp (synced by sync-legacy).
 * DE has full coverage; EN falls back to the DE card when no English map entry
 * exists (currently only "Rachsüchtiger Wolf").
 */
import { LANG } from "./lang";

const BASE = import.meta.env.BASE_URL;

const CARD_MAP_DE_EXCEPTIONS: Record<string, string> = {
  "Loki": "Loki_DE",
  "Dorfchronistin": "Dorfchronistin_DE",
  "Wahnsinniger Kutscher": "Wahnsinniger Kutscher",
  "Voodoo-Priester": "Voodoo_Priester"
};

const CARD_MAP_EN: Record<string, string> = {
  "Loki": "Loki_EN",
  "Nachtwächter": "Night_Warden",
  "Die Gebundenen": "The_Bound",
  "Waldhexe": "Witch_of_the_Woods",
  "Rattenfänger": "Pied_Piper",
  "Sensenträger": "Reaper",
  "Wolfskind": "Wolf_Child",
  "Das Orakel": "The_Oracle",
  "Die Ewigen": "The_Eternal_Ones",
  "Spürhund": "Scent_Hound",
  "Schutzengel": "Guardian_Angel",
  "Werwolf": "Werewolf",
  "König Lykaon": "King_Lycaon",
  "Siegreicher Wolf": "Victorious_Wolf",
  "Seuchenwolf": "Blight_Wolf",
  "Schicksalswolf": "Fate_Wolf",
  "Schattenwanderer": "Shadowwalker",
  "Giftwolf": "Poison_Wolf",
  "Rudelvater": "Pack_Father",
  "Schwarze Witwe": "Black_Widow",
  "Der Weise": "The_Elder",
  "Verdammniswächter": "Doom_Warden",
  "Lehrling": "Apprentice",
  "Wahnsinniger Kutscher": "Mad_Coachman",
  "Korrupter Richter": "Corrupt_Judge",
  "Märtyrerin": "Martyr",
  "Dorfwache": "Village_Guard",
  "Pestbringerin": "Plague_Bringer",
  "Prophet des Untergangs": "Prophet_of_Doom",
  "Spiegelwolf": "Mirror_Wolf",
  "Dämonischer Wolf": "Demonic_Wolf",
  "Trugbilderwolf": "Decoy_Wolf",
  "Schattenhund": "Shadow_Hound",
  "Besessener Wolf": "Possessed_Wolf",
  "Fenrir": "Fenrir",
  "Kutscher": "Coachman",
  "Seelentauscher": "Soul_Swapper",
  "Blutpriester": "Blood_Priest",
  "Traumdeuter": "Dreamer",
  "Henker": "Executioner",
  "Feuerteufel": "Pyromaniac",
  "Voodoo-Priester": "Voodoo_Priest",
  "Blutwolf": "Blood_Wolf",
  "Albtraumwolf": "Nightmare_Wolf",
  "Cerberus": "Cerberus",
  "Ritter": "Knight",
  "Rotkäppchen": "Little_Red_Riding_Hood",
  "Selbstmörder": "Death_Seeker",
  "Kopfgeldjäger": "Bounty_Hunter",
  "König": "King",
  "Dr. Victor Frankenstein": "Dr._Victor_Frankenstein",
  "Nekromant": "Necromancer",
  "Kartenschlucker": "The_Collector",
  "Hades": "Hades",
  "Doktor": "Doctor",
  "Fährtenleser": "Tracker",
  "Waldläufer": "Ranger",
  "Schutzgeist": "Guardian_Spirit",
  "Dorfchronistin": "Village_Chronicler_EN",
  "Wächter am Tor": "Gatewarden",
  "Zeitwächter": "Time_Warden",
  "Amalia": "Amalia",
  "Kriegerin des Lichts": "Warrior_of_Light",
  "Detektiv": "Detective",
  "Dorfschmied": "Village_Blacksmith",
  "Manipulator": "Manipulator",
  "Doppelspion": "Doppelspion",
  "Grabräuber": "Grave_Robber",
  "Parasit": "Parasite",
  "Todesprediger": "Death_Prophet",
  "Dorfbewohner": "Villager"
};

/** Card image URL for a role id in the current language (mirrors getRoleCardPath).
 *  EN uses CARD_MAP_EN; otherwise (and as EN fallback) the DE file = exception or
 *  spaces→underscores. Returns "" for an empty role. */
export function roleCardUrl(role: string): string {
  if (!role) return "";
  if (LANG === "en" && CARD_MAP_EN[role]) {
    return BASE + "assets/cards/en/" + CARD_MAP_EN[role] + ".webp";
  }
  const deFile = CARD_MAP_DE_EXCEPTIONS[role] || role.replace(/ /g, "_");
  return BASE + "assets/cards/de/" + deFile + ".webp";
}
