export interface UserState {
  isLoggedIn: boolean;
  userId: string;
  displayName: string;
}

export interface ThemeState {
  isDarkMode: boolean;
}

export function initAppStore(): void {
  // AppStorage 鍒濆鍖?(浣跨敤浼犵粺鏂瑰紡)
}
