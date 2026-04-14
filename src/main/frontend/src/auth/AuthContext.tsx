import { createContext, useCallback, useContext, useMemo, useState } from "react";
import type { ReactNode } from "react";

interface AuthContextValue {
  token: string | null;
  username: string | null;
  permissions: string[];
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function decodeJwtPayload(token: string): { sub?: string; permissions?: string[]; exp?: number } {
  try {
    const base64Url = token.split(".")[1];
    if (!base64Url) return {};
    const base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
    const json = atob(base64);
    return JSON.parse(json);
  } catch {
    return {};
  }
}

function isTokenExpired(token: string): boolean {
  const payload = decodeJwtPayload(token);
  if (!payload.exp) return true;
  return payload.exp * 1000 < Date.now();
}

function loadStoredAuth(): { token: string | null; username: string | null; permissions: string[] } {
  const stored = localStorage.getItem("auth_token");
  if (stored && !isTokenExpired(stored)) {
    const payload = decodeJwtPayload(stored);
    return { token: stored, username: payload.sub ?? null, permissions: payload.permissions ?? [] };
  }
  if (stored) {
    localStorage.removeItem("auth_token");
  }
  return { token: null, username: null, permissions: [] };
}

const initialAuth = loadStoredAuth();

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(initialAuth.token);
  const [username, setUsername] = useState<string | null>(initialAuth.username);
  const [permissions, setPermissions] = useState<string[]>(initialAuth.permissions);

  const login = useCallback(async (user: string, password: string) => {
    const response = await fetch("/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: user, password }),
    });

    if (!response.ok) {
      const body = await response.json().catch(() => ({ message: "Login failed" }));
      throw new Error(body.message ?? "Login failed");
    }

    const { token: jwt } = await response.json();
    localStorage.setItem("auth_token", jwt);
    const payload = decodeJwtPayload(jwt);
    setToken(jwt);
    setUsername(payload.sub ?? null);
    setPermissions(payload.permissions ?? []);
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem("auth_token");
    setToken(null);
    setUsername(null);
    setPermissions([]);
    window.location.href = "/login";
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({ token, username, permissions, login, logout }),
    [token, username, permissions, login, logout],
  );

  return <AuthContext value={value}>{children}</AuthContext>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
