import type { Event } from "@opencode-ai/sdk";
import type { PluginInput } from "@opencode-ai/plugin";

export const getSession = async (
  client: PluginInput["client"],
  event: Event,
) => {
  if (event.type === "session.idle") {
    return client.session.get({
      path: { id: event.properties.sessionID },
    });
  }
  return null;
};
