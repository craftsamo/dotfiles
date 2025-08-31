import { Event } from "@opencode-ai/sdk";

export const getSubtitle = (eventType: Event["type"]) => {
  switch (eventType) {
    case "session.idle":
      return "Success 😎";
    case "session.error":
      return "Faild 😔";
    default:
      return "Faild 😔";
  }
};
