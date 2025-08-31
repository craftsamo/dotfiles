import path from "path";
import { execSync } from "child_process";
import type { Plugin } from "@opencode-ai/plugin";
import { getSound, getSubtitle, getSession } from "./utils";

export const NotificationPlugin: Plugin = async ({ client, app, $ }) => {
  const TITLE = "OpenCode ⌘";
  const APP_ICON_PATH = path.resolve(__dirname, "../../img/ghostty.png");
  const SENDER = "com.apple.Terminal";
  return {
    event: async ({ event }) => {
      const subTitle = getSubtitle(event.type);
      const sound = getSound(event.type);

      const session = await getSession(client, event);
      if (session?.data?.title.includes("New session")) {
        return;
      }

      if (event.type === "session.idle") {
        const sessionTitle = session?.data?.title;
        const message = `${sessionTitle || "Unknow"} is Completed !`;
        execSync(
          `terminal-notifier -title "${TITLE}" -subtitle "${subTitle}" -message "${message}" -sound "${sound}" -sender "${SENDER}" -appIcon "${APP_ICON_PATH}"`,
        );
      }

      if (event.type === "session.error") {
        const sessionTitle = session?.data?.title;
        const message = `${sessionTitle || "Unknow"} is Error !`;
        execSync(
          `terminal-notifier -title "${TITLE}" -subtitle "${subTitle}" -message "${message}" -sound "${sound}" -sender "${SENDER}" -appIcon "${APP_ICON_PATH}"`,
        );
      }
    },
  };
};
