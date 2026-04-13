import {
  Box,
  Button,
  Flex,
  Heading,
  Image,
  Input,
  Table,
  Text,
} from "@chakra-ui/react";
import { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import { useProducts } from "../hooks/useProducts";
import { useCategories } from "../hooks/useCategories";
import { usePluginContext } from "../plugins/PluginContext";
import { PluginFilterBar } from "../plugins/PluginFilterBar";
import { ConfirmDialog } from "../components/shared/ConfirmDialog";
import { EmptyState } from "../components/shared/EmptyState";
import { PhotoPlaceholder } from "../components/shared/Icons";
import { PrimaryButton } from "../components/shared/PrimaryButton";
import { useAuth } from "../auth/AuthContext";
import { formatDate } from "../utils/format";
import { isValidImageUrl } from "../utils/url";

function formatPrice(price: number): string {
  return `$${price.toFixed(2)}`;
}

const CATEGORY_COLORS: Record<string, string> = {
  Televisions: "#059669",
  "Audio Systems": "#2563EB",
  "Smart Home": "#059669",
  Electronics: "#2563EB",
  Clothing: "#7C3AED",
  "Home & Garden": "#059669",
  Sports: "#D97706",
};

function getCategoryColor(name: string): string {
  return CATEGORY_COLORS[name] ?? "#334155";
}

export function ProductListPage() {
  const { permissions } = useAuth();
  const canEdit = permissions.includes("EDIT");
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [categoryFilter, setCategoryFilter] = useState<number | undefined>(undefined);
  const [sortField, setSortField] = useState<string | undefined>(undefined);
  const [pluginFilters, setPluginFilters] = useState<string[]>([]);
  const debounceRef = useRef<ReturnType<typeof setTimeout>>(null);
  const { getProductListFilters } = usePluginContext();

  useEffect(() => {
    if (debounceRef.current) {
      clearTimeout(debounceRef.current);
    }
    debounceRef.current = setTimeout(() => {
      setSearch(searchInput);
    }, 300);
    return () => {
      if (debounceRef.current) {
        clearTimeout(debounceRef.current);
      }
    };
  }, [searchInput]);

  const { data: products, loading, error, remove } = useProducts({
    search: search || undefined,
    categoryId: categoryFilter,
    sortField,
    pluginFilters: pluginFilters.length > 0 ? pluginFilters : undefined,
  });
  const { data: categories } = useCategories();

  const [deleteId, setDeleteId] = useState<number | null>(null);
  const [deleting, setDeleting] = useState(false);

  async function handleDelete() {
    if (deleteId === null) return;
    setDeleting(true);
    try {
      await remove(deleteId);
      setDeleteId(null);
    } catch {
      // Error is handled by hook
    } finally {
      setDeleting(false);
    }
  }

  function handleSort(field: string) {
    setSortField((prev) => (prev === field ? undefined : field));
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
            Products
          </Heading>
          <Text fontSize="14px" color="#64748B" mt="4px">
            Manage your product catalog
          </Text>
        </Box>
        {canEdit && (
          <PrimaryButton asChild>
            <Link to="/products/new">+ Add Product</Link>
          </PrimaryButton>
        )}
      </Flex>

      <Flex gap="12px" mb="20px" align="center">
        <Flex
          flex="1"
          maxW="360px"
          bg="white"
          border="1px solid"
          borderColor="#E2E8F0"
          borderRadius="8px"
          px="12px"
          align="center"
          gap="8px"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" strokeWidth="2">
            <circle cx="11" cy="11" r="8" />
            <path d="m21 21-4.35-4.35" />
          </svg>
          <Input
            border="none"
            outline="none"
            placeholder="Search products..."
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            _focus={{ boxShadow: "none" }}
          />
        </Flex>
        <select
          role="combobox"
          aria-label="Filter by category"
          value={categoryFilter ?? ""}
          onChange={(e) =>
            setCategoryFilter(e.target.value ? Number(e.target.value) : undefined)
          }
          style={{
            padding: "8px 12px",
            border: "1px solid #E2E8F0",
            borderRadius: "8px",
            fontSize: "14px",
            background: "white",
            color: "#334155",
            minWidth: "160px",
          }}
        >
          <option value="">All Categories</option>
          {categories.map((cat) => (
            <option key={cat.id} value={cat.id}>
              {cat.name}
            </option>
          ))}
        </select>
        <PluginFilterBar
          filters={getProductListFilters()}
          onFilterChange={setPluginFilters}
        />
      </Flex>

      {loading ? (
        <Text>Loading...</Text>
      ) : products.length === 0 ? (
        <EmptyState
          title="No products found"
          description="Create your first product or adjust your filters."
          action={
            canEdit ? (
              <PrimaryButton asChild>
                <Link to="/products/new">+ Add Product</Link>
              </PrimaryButton>
            ) : undefined
          }
        />
      ) : (
        <Box borderRadius="12px" border="1px solid" borderColor="#E2E8F0" overflow="hidden" bg="white">
          <Table.Root size="md">
            <Table.Header>
              <Table.Row bg="white">
                <Table.ColumnHeader
                  fontSize="12px"
                  fontWeight="600"
                  color="brand.500"
                  textTransform="uppercase"
                  letterSpacing="0.05em"
                  width="60px"
                >
                  Photo
                </Table.ColumnHeader>
                <Table.ColumnHeader
                  fontSize="12px"
                  fontWeight="600"
                  color="brand.500"
                  textTransform="uppercase"
                  letterSpacing="0.05em"
                  cursor="pointer"
                  onClick={() => handleSort("name")}
                >
                  Name {sortField === "name" ? "^" : ""}
                </Table.ColumnHeader>
                <Table.ColumnHeader
                  fontSize="12px"
                  fontWeight="600"
                  color="brand.500"
                  textTransform="uppercase"
                  letterSpacing="0.05em"
                >
                  SKU
                </Table.ColumnHeader>
                <Table.ColumnHeader
                  fontSize="12px"
                  fontWeight="600"
                  color="brand.500"
                  textTransform="uppercase"
                  letterSpacing="0.05em"
                  cursor="pointer"
                  onClick={() => handleSort("price")}
                >
                  Price {sortField === "price" ? "^" : ""}
                </Table.ColumnHeader>
                <Table.ColumnHeader
                  fontSize="12px"
                  fontWeight="600"
                  color="brand.500"
                  textTransform="uppercase"
                  letterSpacing="0.05em"
                >
                  Category
                </Table.ColumnHeader>
                <Table.ColumnHeader
                  fontSize="12px"
                  fontWeight="600"
                  color="brand.500"
                  textTransform="uppercase"
                  letterSpacing="0.05em"
                  cursor="pointer"
                  onClick={() => handleSort("createdAt")}
                >
                  Created {sortField === "createdAt" ? "^" : ""}
                </Table.ColumnHeader>
                {canEdit && (
                  <Table.ColumnHeader
                    fontSize="12px"
                    fontWeight="600"
                    color="brand.500"
                    textTransform="uppercase"
                    letterSpacing="0.05em"
                    width="120px"
                  >
                    Actions
                  </Table.ColumnHeader>
                )}
              </Table.Row>
            </Table.Header>
            <Table.Body>
              {products.map((product) => {
                const categoryColor = getCategoryColor(product.category.name);
                return (
                  <Table.Row key={product.id} _hover={{ bg: "#F8FAFC" }}>
                    <Table.Cell>
                      <Box
                        w="40px"
                        h="40px"
                        borderRadius="8px"
                        overflow="hidden"
                        bg="#F1F5F9"
                        display="flex"
                        alignItems="center"
                        justifyContent="center"
                      >
                        {isValidImageUrl(product.photoUrl) ? (
                          <Image
                            src={product.photoUrl!}
                            alt={product.name}
                            w="100%"
                            h="100%"
                            objectFit="cover"
                          />
                        ) : (
                          <PhotoPlaceholder />
                        )}
                      </Box>
                    </Table.Cell>
                    <Table.Cell fontWeight="500" color="#1E293B">
                      <Link
                        to={`/products/${product.id}`}
                        style={{ textDecoration: "none", color: "inherit" }}
                        aria-label={product.name}
                      >
                        {product.name}
                      </Link>
                    </Table.Cell>
                    <Table.Cell fontFamily="monospace" fontSize="13px" color="#64748B">
                      {product.sku}
                    </Table.Cell>
                    <Table.Cell fontWeight="600" color="#0F172A">
                      {formatPrice(product.price)}
                    </Table.Cell>
                    <Table.Cell>
                      <Text
                        as="span"
                        fontSize="13px"
                        fontWeight="500"
                        color={categoryColor}
                      >
                        {product.category.name}
                      </Text>
                    </Table.Cell>
                    <Table.Cell color="#64748B" fontSize="13px">
                      {formatDate(product.createdAt)}
                    </Table.Cell>
                    {canEdit && (
                      <Table.Cell>
                        <Flex gap="8px">
                          <Button
                            asChild
                            variant="ghost"
                            size="sm"
                            color="#334155"
                            fontWeight="500"
                            aria-label={`Edit ${product.name}`}
                          >
                            <Link to={`/products/${product.id}/edit`}>Edit</Link>
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            color="#DC2626"
                            fontWeight="500"
                            aria-label={`Delete ${product.name}`}
                            onClick={() => setDeleteId(product.id)}
                          >
                            Delete
                          </Button>
                        </Flex>
                      </Table.Cell>
                    )}
                  </Table.Row>
                );
              })}
            </Table.Body>
          </Table.Root>
          <Box px="16px" py="12px" fontSize="13px" color="#64748B">
            Showing {products.length} {products.length === 1 ? "product" : "products"}
          </Box>
        </Box>
      )}

      <ConfirmDialog
        open={deleteId !== null}
        onClose={() => setDeleteId(null)}
        onConfirm={handleDelete}
        title="Delete Product"
        message="Are you sure you want to delete this product? This action cannot be undone."
        loading={deleting}
      />
    </Box>
  );
}
