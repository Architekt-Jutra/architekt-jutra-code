import { render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi, beforeEach } from "vitest";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { ChakraProvider } from "@chakra-ui/react";
import { system } from "../theme";
import type { PluginResponse } from "../api/plugins";
import type { ProductResponse } from "../api/products";
import type { CategoryResponse } from "../api/categories";
import { MENU_MAIN, PRODUCT_DETAIL_TABS, PRODUCT_LIST_FILTERS } from "../plugins/extensionPoints";
import * as pluginsApi from "../api/plugins";
import * as productsApi from "../api/products";
import * as categoriesApi from "../api/categories";

vi.mock("../auth/AuthContext", async (importOriginal) => {
  const actual = await importOriginal<typeof import("../auth/AuthContext")>();
  return {
    ...actual,
    useAuth: vi.fn(() => ({
      token: "test-token",
      username: "admin",
      permissions: ["EDIT", "PLUGIN_MANAGEMENT"],
      login: vi.fn(),
      logout: vi.fn(),
    })),
  };
});

vi.mock("../api/plugins", () => ({
  getPlugins: vi.fn(),
  getPlugin: vi.fn(),
  uploadManifest: vi.fn(),
  deletePlugin: vi.fn(),
  setPluginEnabled: vi.fn(),
}));

vi.mock("../api/products", () => ({
  getProducts: vi.fn(),
  getProduct: vi.fn(),
  createProduct: vi.fn(),
  updateProduct: vi.fn(),
  deleteProduct: vi.fn(),
}));

vi.mock("../api/categories", () => ({
  getCategories: vi.fn(),
  getCategory: vi.fn(),
  createCategory: vi.fn(),
  updateCategory: vi.fn(),
  deleteCategory: vi.fn(),
}));

const mockCategories: CategoryResponse[] = [
  { id: 1, name: "Electronics", description: "Gadgets", createdAt: "2026-03-20T10:00:00Z", updatedAt: "2026-03-20T10:00:00Z" },
];

const mockPlugins: PluginResponse[] = [
  {
    id: "warehouse",
    name: "Warehouse Management",
    version: "1.0.0",
    url: "http://localhost:3001",
    description: "Manages warehouse inventory",
    enabled: true,
    extensionPoints: [
      { type: MENU_MAIN, label: "Warehouse", path: "/warehouse", priority: 100 },
      { type: PRODUCT_DETAIL_TABS, label: "Stock", path: "/stock", priority: 50 },
      { type: PRODUCT_LIST_FILTERS, label: "Warehouse Filter", path: "/filters", priority: 10 },
    ],
  },
  {
    id: "analytics",
    name: "Analytics Dashboard",
    version: "2.0.0",
    url: "http://localhost:3002",
    description: "Product analytics",
    enabled: true,
    extensionPoints: [
      { type: MENU_MAIN, label: "Analytics", path: "/analytics", priority: 200 },
      { type: PRODUCT_DETAIL_TABS, label: "Insights", path: "/insights", priority: 30 },
    ],
  },
  {
    id: "disabled-plugin",
    name: "Disabled Plugin",
    version: "0.1.0",
    url: "http://localhost:3003",
    description: "Should not appear in sidebar",
    enabled: false,
    extensionPoints: [
      { type: MENU_MAIN, label: "Disabled", path: "/disabled", priority: 50 },
    ],
  },
];

const mockProduct: ProductResponse = {
  id: 42,
  name: "Wireless Headphones Pro",
  description: "Premium wireless headphones with noise cancellation",
  photoUrl: "https://example.com/headphones.jpg",
  price: 149.99,
  sku: "WHP-001",
  category: mockCategories[0]!,
  pluginData: null,
  createdAt: "2026-03-28T10:00:00Z",
  updatedAt: "2026-03-28T10:00:00Z",
};

const mockProducts: ProductResponse[] = [mockProduct];

function renderWithProviders(ui: React.ReactElement, initialRoute = "/") {
  return render(
    <ChakraProvider value={system}>
      <MemoryRouter initialEntries={[initialRoute]}>{ui}</MemoryRouter>
    </ChakraProvider>,
  );
}

beforeEach(() => {
  vi.resetAllMocks();
  vi.mocked(pluginsApi.getPlugins).mockResolvedValue(mockPlugins);
  vi.mocked(productsApi.getProducts).mockResolvedValue(mockProducts);
  vi.mocked(productsApi.getProduct).mockResolvedValue(mockProduct);
  vi.mocked(categoriesApi.getCategories).mockResolvedValue(mockCategories);
});

describe("Sidebar with plugin menu items", () => {
  it("renders hardcoded items then plugin menu items", async () => {
    const { PluginProvider } = await import("../plugins/PluginContext");
    const { Sidebar } = await import("../components/layout/Sidebar");

    renderWithProviders(
      <PluginProvider>
        <Sidebar />
      </PluginProvider>,
    );

    // Hardcoded items should be present immediately
    expect(screen.getByText("Products")).toBeInTheDocument();
    expect(screen.getByText("Categories")).toBeInTheDocument();
    expect(screen.getByText("Plugins")).toBeInTheDocument();

    // Plugin-contributed menu items appear after loading
    expect(await screen.findByText("Warehouse")).toBeInTheDocument();
    expect(screen.getByText("Analytics")).toBeInTheDocument();

    // Disabled plugins should NOT appear
    expect(screen.queryByText("Disabled")).not.toBeInTheDocument();
  });
});

describe("ProductDetailPage", () => {
  it("renders product info in Details tab and plugin tabs", async () => {
    const { PluginProvider } = await import("../plugins/PluginContext");
    const { ProductDetailPage } = await import("../pages/ProductDetailPage");

    render(
      <ChakraProvider value={system}>
        <PluginProvider>
          <MemoryRouter initialEntries={["/products/42"]}>
            <Routes>
              <Route path="/products/:id" element={<ProductDetailPage />} />
            </Routes>
          </MemoryRouter>
        </PluginProvider>
      </ChakraProvider>,
    );

    // Product info should load
    expect(await screen.findByRole("heading", { name: "Wireless Headphones Pro" })).toBeInTheDocument();
    expect(screen.getByText("$149.99")).toBeInTheDocument();
    expect(screen.getByText("WHP-001")).toBeInTheDocument();

    // Tab navigation: Details tab plus plugin tabs
    expect(screen.getByRole("tab", { name: /details/i })).toBeInTheDocument();
    expect(screen.getByRole("tab", { name: /insights/i })).toBeInTheDocument();
    expect(screen.getByRole("tab", { name: /stock/i })).toBeInTheDocument();

    // Plugin tabs should render iframes (hidden initially since Details tab is active)
    const iframes = document.querySelectorAll("iframe");
    expect(iframes.length).toBe(2); // One per plugin tab
  });
});

describe("ProductListPage with plugin filters", () => {
  it("renders plugin filter iframes in filter bar", async () => {
    const { PluginProvider } = await import("../plugins/PluginContext");
    const { ProductListPage } = await import("../pages/ProductListPage");

    renderWithProviders(
      <PluginProvider>
        <ProductListPage />
      </PluginProvider>,
    );

    // Product data loads
    expect(await screen.findByText("Wireless Headphones Pro")).toBeInTheDocument();

    // Plugin filter iframes should be rendered
    const iframes = document.querySelectorAll("iframe");
    expect(iframes.length).toBeGreaterThanOrEqual(1);

    // Product rows should link to detail page
    const productLinks = screen.getAllByRole("link", { name: /wireless headphones pro/i });
    const detailLink = productLinks.find((link) => link.getAttribute("href") === "/products/42");
    expect(detailLink).toBeTruthy();
  });
});

describe("Plugin page route", () => {
  it("renders full-page PluginFrame for /plugins/:pluginId/*", async () => {
    const { PluginProvider } = await import("../plugins/PluginContext");
    const { PluginPageRoute } = await import("../pages/PluginPageRoute");

    render(
      <ChakraProvider value={system}>
        <PluginProvider>
          <MemoryRouter initialEntries={["/plugins/warehouse/some/path"]}>
            <Routes>
              <Route path="/plugins/:pluginId/*" element={<PluginPageRoute />} />
            </Routes>
          </MemoryRouter>
        </PluginProvider>
      </ChakraProvider>,
    );

    // Wait for plugins to load and iframe to render
    await waitFor(() => {
      const iframe = document.querySelector("iframe");
      expect(iframe).toBeTruthy();
    });

    const iframe = document.querySelector("iframe");
    expect(iframe?.title).toContain("Warehouse Management");
  });
});

describe("ProductDetailPage with no plugins", () => {
  it("renders only Details tab when no plugins are loaded", async () => {
    vi.mocked(pluginsApi.getPlugins).mockResolvedValue([]);

    const { PluginProvider } = await import("../plugins/PluginContext");
    const { ProductDetailPage } = await import("../pages/ProductDetailPage");

    render(
      <ChakraProvider value={system}>
        <PluginProvider>
          <MemoryRouter initialEntries={["/products/42"]}>
            <Routes>
              <Route path="/products/:id" element={<ProductDetailPage />} />
            </Routes>
          </MemoryRouter>
        </PluginProvider>
      </ChakraProvider>,
    );

    // Product info should load
    expect(await screen.findByRole("heading", { name: "Wireless Headphones Pro" })).toBeInTheDocument();

    // Only Details tab should exist, no plugin tabs
    expect(screen.getByRole("tab", { name: /details/i })).toBeInTheDocument();
    expect(screen.queryByRole("tab", { name: /insights/i })).not.toBeInTheDocument();
    expect(screen.queryByRole("tab", { name: /stock/i })).not.toBeInTheDocument();

    // No iframes should be rendered
    const iframes = document.querySelectorAll("iframe");
    expect(iframes.length).toBe(0);
  });
});

describe("PluginListPage", () => {
  it("renders table of plugins with name, version, URL, enabled columns", async () => {
    const { PluginProvider } = await import("../plugins/PluginContext");
    const { PluginListPage } = await import("../pages/PluginListPage");

    renderWithProviders(
      <PluginProvider>
        <PluginListPage />
      </PluginProvider>,
    );

    // All plugins should be listed (including disabled)
    expect(await screen.findByText("Warehouse Management")).toBeInTheDocument();
    expect(screen.getByText("Analytics Dashboard")).toBeInTheDocument();
    expect(screen.getByText("Disabled Plugin")).toBeInTheDocument();

    // Version and URL columns
    expect(screen.getByText("1.0.0")).toBeInTheDocument();
    expect(screen.getByText("http://localhost:3001")).toBeInTheDocument();

    // Column headers
    expect(screen.getByText("Name")).toBeInTheDocument();
    expect(screen.getByText("Version")).toBeInTheDocument();
    expect(screen.getByText("URL")).toBeInTheDocument();
    expect(screen.getByText("Enabled")).toBeInTheDocument();

    // Add Plugin button
    expect(screen.getByRole("link", { name: /add plugin/i })).toBeInTheDocument();
  });
});
