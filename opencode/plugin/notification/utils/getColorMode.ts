import { execSync } from "child_process";

export const getColorMode = () => {
  try {
    execSync("defaults read -g AppleInterfaceStyle", {
      encoding: "utf8",
    });
    return { id: "dark", name: "Dark" };
  } catch (e) {
    return { id: "light", name: "Light" };
  }
};
