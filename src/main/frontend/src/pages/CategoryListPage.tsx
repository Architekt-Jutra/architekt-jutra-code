import {
  Box,
  Button,
  Flex,
  Heading,
  Table,
  Text,
} from "@chakra-ui/react";
import { useState } from "react";
import { Link } from "react-router-dom";
import { useCategories } from "../hooks/useCategories";
import { ConfirmDialog } from "../components/shared/ConfirmDialog";
import { EmptyState } from "../components/shared/EmptyState";
import { useAuth } from "../auth/AuthContext";
import { formatDate } from "../utils/format";
import { PrimaryButton } from "../components/shared/PrimaryButton";

function truncate(text: string | null, maxLength: number): string {
  if (!text) return "";
  return text.length > maxLength ? text.slice(0, maxLength) + "..." : text;
}

export function CategoryListPage() {
  const { permissions } = useAuth();
  const canEdit = permissions.includes("EDIT");
  const { data: categories, loading, error, remove } = useCategories();
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);

  async function handleDelete() {
    if (deleteId === null) return;
    setDeleting(true);
    setDeleteError(null);
    try {
      await remove(deleteId);
      setDeleteId(null);
    } catch (err) {
      if (err instanceof Error && err.message.includes("409")) {
        setDeleteError("Category has products and cannot be deleted.");
      } else {
        setDeleteError("Failed to delete category.");
      }
    } finally {
      setDeleting(false);
    }
  }

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
            Categories
          </Heading>
          <Text fontSize="14px" color="#64748B" mt="4px">
            Organize products into categories
          </Text>
        </Box>
        {canEdit && (
          <PrimaryButton asChild>
            <Link to="/categories/new">+ Add Category</Link>
          </PrimaryButton>
        )}
      </Flex>

      {loading ? (
        <Text>Loading...</Text>
      ) : categories.length === 0 ? (
        <EmptyState
          title="No categories yet"
          description="Create your first category to organize products."
          action={
            canEdit ? (
              <PrimaryButton asChild>
                <Link to="/categories/new">+ Add Category</Link>
              </PrimaryButton>
            ) : undefined
          }
        />
      ) : (
        <Box borderRadius="12px" border="1px solid" borderColor="#E2E8F0" overflow="hidden" bg="white">
          <Table.Root size="md">
            <Table.Header>
              <Table.Row bg="brand.50">
                <Table.ColumnHeader
                  fontSize="12px"
                  fontWeight="600"
                  color="brand.600"
                  textTransform="uppercase"
                  letterSpacing="0.05em"
                >
                  Name
                </Table.ColumnHeader>
                <Table.ColumnHeader
                  fontSize="12px"
                  fontWeight="600"
                  color="brand.600"
                  textTransform="uppercase"
                  letterSpacing="0.05em"
                >
                  Description
                </Table.ColumnHeader>
                <Table.ColumnHeader
                  fontSize="12px"
                  fontWeight="600"
                  color="brand.600"
                  textTransform="uppercase"
                  letterSpacing="0.05em"
                >
                  Created
                </Table.ColumnHeader>
                {canEdit && (
                  <Table.ColumnHeader
                    fontSize="12px"
                    fontWeight="600"
                    color="brand.600"
                    textTransform="uppercase"
                    letterSpacing="0.05em"
                    textAlign="center"
                    width="100px"
                  >
                    Actions
                  </Table.ColumnHeader>
                )}
              </Table.Row>
            </Table.Header>
            <Table.Body>
              {categories.map((category) => (
                <Table.Row key={category.id} _hover={{ bg: "#F8FAFC" }}>
                  <Table.Cell fontWeight="600" color="#1E293B">
                    {category.name}
                  </Table.Cell>
                  <Table.Cell color="#64748B" maxW="300px">
                    {truncate(category.description, 60)}
                  </Table.Cell>
                  <Table.Cell color="#64748B" fontSize="13px">
                    {formatDate(category.createdAt)}
                  </Table.Cell>
                  {canEdit && (
                    <Table.Cell textAlign="center">
                      <Flex gap="4px" justify="center">
                        <Button asChild variant="ghost" size="sm" aria-label={`Edit ${category.name}`}>
                          <Link to={`/categories/${category.id}/edit`}>Edit</Link>
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          colorPalette="red"
                          aria-label={`Delete ${category.name}`}
                          onClick={() => setDeleteId(category.id)}
                        >
                          Delete
                        </Button>
                      </Flex>
                    </Table.Cell>
                  )}
                </Table.Row>
              ))}
            </Table.Body>
          </Table.Root>
          <Box px="16px" py="12px" fontSize="13px" color="#64748B">
            Showing {categories.length} {categories.length === 1 ? "category" : "categories"}
          </Box>
        </Box>
      )}

      <Box
        mt="16px"
        p="12px 16px"
        bg="accent.50"
        border="1px solid"
        borderColor="accent.200"
        borderRadius="8px"
        fontSize="13px"
        color="accent.800"
      >
        Categories with products cannot be deleted. Reassign products first.
      </Box>

      {deleteError && (
        <Box mt="8px" p="12px 16px" bg="#FEE2E2" borderRadius="8px" fontSize="13px" color="#991B1B">
          {deleteError}
        </Box>
      )}

      <ConfirmDialog
        open={deleteId !== null}
        onClose={() => setDeleteId(null)}
        onConfirm={handleDelete}
        title="Delete Category"
        message="Are you sure you want to delete this category? This action cannot be undone."
        loading={deleting}
      />
    </Box>
  );
}
