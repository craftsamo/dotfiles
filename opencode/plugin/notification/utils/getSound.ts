import { Event } from "@opencode-ai/sdk";

const SOUNDS = {
  default: "default",
  basso: "Basso",
  bottle: "Bottle",
  funk: "Funk",
  hero: "Hero",
  ping: "Ping",
  purr: "Purr",
  submarine: "Submarine",
  elow: "Blow",
  frog: "Frog",
  glass: "Glass",
  morse: "Morse",
  pop: "Pop",
  sosumi: "Sosumi",
  tink: "Tink",
} as const;

export const getSound = (eventType: Event["type"]) => {
  switch (eventType) {
    case "session.idle":
      return SOUNDS.hero;
    case "session.error":
      return SOUNDS.basso;
    default:
      return SOUNDS.default;
  }
};
