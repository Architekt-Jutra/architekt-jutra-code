import { Box, Flex, Text } from "@chakra-ui/react";
import { Link, useLocation } from "react-router-dom";
import type { LucideIcon } from "lucide-react";
import { ProductsIcon, CategoriesIcon, PluginsIcon, resolveIcon } from "../shared/Icons";
import { usePluginContext } from "../../plugins/PluginContext";
import { useAuth } from "../../auth/AuthContext";

interface NavItemProps {
  to: string;
  label: string;
  icon: LucideIcon;
}

function NavItem({ to, label, icon: Icon }: NavItemProps) {
  const location = useLocation();
  const isActive = location.pathname.startsWith(to);

  return (
    <Flex asChild px="12px">
      <Link
        to={to}
        style={{
          display: "flex",
          alignItems: "center",
          gap: "10px",
          padding: "10px 16px",
          fontSize: "14px",
          fontWeight: 500,
          textDecoration: "none",
          color: isActive ? "white" : "rgba(255,255,255,0.7)",
          background: isActive ? "rgba(59,130,246,0.35)" : "transparent",
          borderRadius: "8px",
          transition: "all 0.15s",
        }}
      >
        <Icon size={18} />
        {label}
      </Link>
    </Flex>
  );
}

function PluginMenuItems() {
  const { getMenuItems, loading } = usePluginContext();

  if (loading) return null;

  const menuItems = getMenuItems();
  if (menuItems.length === 0) return null;

  return (
    <>
      {menuItems.map((item) => (
        <NavItem
          key={`${item.pluginId}-${item.path}`}
          to={`/plugins/${item.pluginId}${item.path}`}
          label={item.label ?? item.pluginName}
          icon={resolveIcon(item.icon)}
        />
      ))}
    </>
  );
}

export function Sidebar() {
  const { permissions } = useAuth();
  const hasPluginManagement = permissions.includes("PLUGIN_MANAGEMENT");

  return (
    <Box
      as="aside"
      w="220px"
      bg="brand.900"
      color="white"
      py="24px"
      flexShrink={0}
      display={{ base: "none", md: "block" }}
    >
      <Text
        fontSize="15px"
        fontWeight="700"
        px="24px"
        pb="32px"
        letterSpacing="-0.3px"
        whiteSpace="nowrap"
      >
        <Text as="span" color="brand.400">Tomorrow</Text>
        <Text as="span" color="white" fontWeight="800">Commerce</Text>
      </Text>
      <Flex as="nav" direction="column" gap="2px" role="navigation" aria-label="Main navigation">
        <NavItem to="/products" label="Products" icon={ProductsIcon} />
        <NavItem to="/categories" label="Categories" icon={CategoriesIcon} />
        {hasPluginManagement && (
          <NavItem to="/plugins" label="Plugins" icon={PluginsIcon} />
        )}
        {hasPluginManagement && <PluginMenuItems />}
      </Flex>
    </Box>
  );
}
