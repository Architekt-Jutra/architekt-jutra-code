import { Navigate } from "react-router-dom";
import { useAuth } from "./AuthContext";
import type { ReactNode } from "react";

interface AuthGuardProps {
  children: ReactNode;
  requireAuth?: boolean;
}

export function AuthGuard({ children, requireAuth = true }: AuthGuardProps) {
  const { token } = useAuth();

  if (requireAuth && !token) {
    return <Navigate to="/login" replace />;
  }

  if (!requireAuth && token) {
    return <Navigate to="/products" replace />;
  }

  return <>{children}</>;
}
