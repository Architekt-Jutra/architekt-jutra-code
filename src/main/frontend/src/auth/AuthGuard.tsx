import { Navigate, useLocation, useSearchParams } from "react-router-dom";
import { useAuth } from "./AuthContext";
import type { ReactNode } from "react";

interface AuthGuardProps {
  children: ReactNode;
  requireAuth?: boolean;
}

export function AuthGuard({ children, requireAuth = true }: AuthGuardProps) {
  const { token } = useAuth();
  const location = useLocation();
  const [searchParams] = useSearchParams();

  if (requireAuth && !token) {
    const returnTo = location.pathname + location.search;
    return <Navigate to={`/login?returnTo=${encodeURIComponent(returnTo)}`} replace />;
  }

  if (!requireAuth && token) {
    const returnTo = searchParams.get("returnTo") || "/products";
    return <Navigate to={returnTo} replace />;
  }

  return <>{children}</>;
}
