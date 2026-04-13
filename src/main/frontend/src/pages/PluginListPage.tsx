import {
  Box,
  Flex,
  Heading,
  Table,
  Text,
} from "@chakra-ui/react";
import { Link } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import { usePluginContext } from "../plugins/PluginContext";
import { PrimaryButton } from "../components/shared/PrimaryButton";

export function PluginListPage() {
  const { permissions } = useAuth();
  const canManagePlugins = permissions.includes("PLUGIN_MANAGEMENT");
  const { plugins, loading, error } = usePluginContext();

  if (error) {
    return (
      <Box>
        <Text color="red.500">Error: {error}</Text>
      </Box>
    );
  }

  return (
    <Box>
      <Flex justify="space-between" align="flex-start" mb="24px">
        <Box>
          <Heading as="h1" fontSize="24px" fontWeight="700" color="#0F172A">
            Plugins
          </Heading>
          <Text fontSize="14px" color="#64748B" mt="4px">
            Manage installed plugins
          </Text>
        </Box>
        {canManagePlugins && (
          <PrimaryButton asChild>
            <Link to="/plugins/new">+ Add Plugin</Link>
          </PrimaryButton>
        )}
      </Flex>

      {loading ? (
        <Text>Loading...</Text>
      ) : plugins.length === 0 ? (
        <Box bg="white" border="1px solid" borderColor="#E2E8F0" borderRadius="12px" p="32px" textAlign="center">
          <Text color="#64748B">No plugins installed yet.</Text>
        </Box>
      ) : (
        <Box borderRadius="12px" border="1px solid" borderColor="#E2E8F0" overflow="hidden" bg="white">
          <Table.Root size="md">
            <Table.Header>
              <Table.Row bg="brand.50">
                <Table.ColumnHeader fontSize="12px" fontWeight="600" color="brand.600" textTransform="uppercase" letterSpacing="0.05em">
                  Name
                </Table.ColumnHeader>
                <Table.ColumnHeader fontSize="12px" fontWeight="600" color="brand.600" textTransform="uppercase" letterSpacing="0.05em">
                  Plugin ID
                </Table.ColumnHeader>
                <Table.ColumnHeader fontSize="12px" fontWeight="600" color="brand.600" textTransform="uppercase" letterSpacing="0.05em">
                  Version
                </Table.ColumnHeader>
                <Table.ColumnHeader fontSize="12px" fontWeight="600" color="brand.600" textTransform="uppercase" letterSpacing="0.05em">
                  URL
                </Table.ColumnHeader>
                <Table.ColumnHeader fontSize="12px" fontWeight="600" color="brand.600" textTransform="uppercase" letterSpacing="0.05em">
                  Enabled
                </Table.ColumnHeader>
              </Table.Row>
            </Table.Header>
            <Table.Body>
              {plugins.map((plugin) => (
                <Table.Row key={plugin.id} _hover={{ bg: "#F8FAFC" }}>
                  <Table.Cell fontWeight="600" color="#1E293B">
                    <Link
                      to={`/plugins/${plugin.id}/detail`}
                      style={{ textDecoration: "none", color: "inherit" }}
                    >
                      {plugin.name}
                    </Link>
                  </Table.Cell>
                  <Table.Cell fontFamily="monospace" fontSize="13px" color="#64748B">
                    {plugin.id}
                  </Table.Cell>
                  <Table.Cell color="#334155">
                    {plugin.version}
                  </Table.Cell>
                  <Table.Cell fontSize="13px" color="#64748B">
                    {plugin.url}
                  </Table.Cell>
                  <Table.Cell>
                    <Text
                      as="span"
                      px="10px"
                      py="4px"
                      borderRadius="20px"
                      fontSize="12px"
                      fontWeight="600"
                      bg={plugin.enabled ? "#D1FAE5" : "#FEE2E2"}
                      color={plugin.enabled ? "#065F46" : "#991B1B"}
                    >
                      {plugin.enabled ? "Yes" : "No"}
                    </Text>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table.Body>
          </Table.Root>
          <Box px="16px" py="12px" fontSize="13px" color="#64748B">
            Showing {plugins.length} {plugins.length === 1 ? "plugin" : "plugins"}
          </Box>
        </Box>
      )}
    </Box>
  );
}
