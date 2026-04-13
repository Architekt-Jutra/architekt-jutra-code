import { Button, Flex, IconButton, Text } from "@chakra-ui/react";
import { useLocation } from "react-router-dom";
import { useAuth } from "../../auth/AuthContext";

function MenuIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M3 12h18M3 6h18M3 18h18" />
    </svg>
  );
}

interface HeaderProps {
  onMenuOpen: () => void;
}

function getBreadcrumbs(pathname: string): string[] {
  const segments = pathname.split("/").filter(Boolean);
  const crumbs: string[] = [];

  if (segments[0] === "products") {
    crumbs.push("Products");
    if (segments[1] === "new") crumbs.push("New Product");
    else if (segments[2] === "edit") crumbs.push("Edit Product");
  } else if (segments[0] === "categories") {
    crumbs.push("Categories");
    if (segments[1] === "new") crumbs.push("New Category");
    else if (segments[2] === "edit") crumbs.push("Edit Category");
  }

  return crumbs;
}

export function Header({ onMenuOpen }: HeaderProps) {
  const location = useLocation();
  const breadcrumbs = getBreadcrumbs(location.pathname);
  const { username, logout } = useAuth();

  return (
    <Flex
      as="header"
      align="center"
      gap="12px"
      px={{ base: "16px", md: "40px" }}
      py="12px"
      borderBottom="1px solid"
      borderColor="#E2E8F0"
      bg="white"
    >
      <IconButton
        aria-label="Open menu"
        variant="ghost"
        display={{ base: "flex", md: "none" }}
        onClick={onMenuOpen}
        size="sm"
      >
        <MenuIcon />
      </IconButton>
      <Flex as="nav" aria-label="Breadcrumb" gap="8px" align="center">
        {breadcrumbs.map((crumb, index) => (
          <Flex key={crumb} align="center" gap="8px">
            {index > 0 && (
              <Text color="#94A3B8" fontSize="14px">
                /
              </Text>
            )}
            <Text
              fontSize="14px"
              fontWeight={index === breadcrumbs.length - 1 ? "600" : "400"}
              color={index === breadcrumbs.length - 1 ? "#0F172A" : "#64748B"}
            >
              {crumb}
            </Text>
          </Flex>
        ))}
      </Flex>
      <Flex ml="auto" align="center" gap="12px">
        {username && (
          <Text fontSize="13px" color="#64748B">
            {username}
          </Text>
        )}
        <Button variant="ghost" size="sm" onClick={logout} aria-label="Logout">
          Logout
        </Button>
      </Flex>
    </Flex>
  );
}
