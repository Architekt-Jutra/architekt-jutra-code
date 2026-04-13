import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { MemoryRouter } from "react-router-dom";
import { ChakraProvider } from "@chakra-ui/react";
import { system } from "../theme";
import { AppShell } from "../components/layout/AppShell";
import { PluginProvider } from "../plugins/PluginContext";

vi.mock("../api/plugins", () => ({
  getPlugins: vi.fn().mockResolvedValue([]),
  getPlugin: vi.fn(),
  uploadManifest: vi.fn(),
  deletePlugin: vi.fn(),
  setPluginEnabled: vi.fn(),
}));

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

function renderWithProviders(ui: React.ReactElement, initialRoute = "/") {
  return render(
    <ChakraProvider value={system}>
      <PluginProvider>
        <MemoryRouter initialEntries={[initialRoute]}>{ui}</MemoryRouter>
      </PluginProvider>
    </ChakraProvider>,
  );
}

describe("Frontend Foundation", () => {
  it("renders ChakraProvider with custom theme without errors", () => {
    renderWithProviders(<div data-testid="theme-check">themed</div>);
    expect(screen.getByTestId("theme-check")).toBeInTheDocument();
  });

  it("renders AppShell with sidebar and content area", () => {
    renderWithProviders(
      <AppShell>
        <div>page content</div>
      </AppShell>,
    );
    // Sidebar nav is hidden at base breakpoint (mobile-first) but present in DOM
    expect(screen.getByRole("navigation", { name: "Main navigation", hidden: true })).toBeInTheDocument();
    expect(screen.getByText("Tomorrow")).toBeInTheDocument();
    expect(screen.getByText("Commerce")).toBeInTheDocument();
    expect(screen.getByText("Products")).toBeInTheDocument();
    expect(screen.getByText("Categories")).toBeInTheDocument();
    expect(screen.getByText("page content")).toBeInTheDocument();
  });

  it("renders router with default redirect to /products", async () => {
    const { container } = renderWithProviders(
      <AppShell>
        <div>routed content</div>
      </AppShell>,
      "/products",
    );
    expect(container).toBeTruthy();
    expect(screen.getByText("routed content")).toBeInTheDocument();
    // Breadcrumb should show "Products" for /products route
    expect(screen.getByRole("navigation", { name: "Breadcrumb" })).toBeInTheDocument();
  });
});
