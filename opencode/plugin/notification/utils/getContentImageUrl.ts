import { getColorMode } from "./getColorMode";

export const getContentImageUrl = () => {
  const colorMode = getColorMode();
  return `https://registry.npmmirror.com/@lobehub/icons-static-png/1.63.0/files/${colorMode.id}/githubcopilot.png`;
};
