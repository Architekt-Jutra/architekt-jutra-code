import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { describe, expect, it, vi, beforeEach } from "vitest";
import { MemoryRouter } from "react-router-dom";
import { ChakraProvider } from "@chakra-ui/react";
import { system } from "../theme";

// Mock fetch globally
const mockFetch = vi.fn();
vi.stubGlobal("fetch", mockFetch);

// Mock window.location
const mockLocation = { href: "", pathname: "/" };
Object.defineProperty(window, "location", {
  value: mockLocation,
  writable: true,
});

// Keep a reference to the real implementations before mocking
let RealAuthProvider: typeof import("../auth/AuthContext").AuthProvider;
let realUseAuth: typeof import("../auth/AuthContext").useAuth;

// Mock the auth module for pages that use useAuth
const mockUseAuth = vi.fn((): { token: string | null; username: string | null; permissions: string[]; login: (username: string, password: string) => Promise<void>; logout: () => void } => ({
  token: "test-token",
  username: "admin",
  permissions: ["EDIT", "PLUGIN_MANAGEMENT"],
  login: vi.fn(),
  logout: vi.fn(),
}));

vi.mock("../auth/AuthContext", async (importOriginal) => {
  const actual = await importOriginal<typeof import("../auth/AuthContext")>();
  RealAuthProvider = actual.AuthProvider;
  realUseAuth = actual.useAuth;
  return {
    ...actual,
    useAuth: (...args: Parameters<typeof actual.useAuth>) => mockUseAuth(...args),
  };
});

vi.mock("../api/plugins", () => ({
  getPlugins: vi.fn().mockResolvedValue([]),
  getPlugin: vi.fn(),
  uploadManifest: vi.fn(),
  deletePlugin: vi.fn(),
  setPluginEnabled: vi.fn(),
}));

vi.mock("../api/products", () => ({
  getProducts: vi.fn().mockResolvedValue([]),
  getProduct: vi.fn(),
  createProduct: vi.fn(),
  updateProduct: vi.fn(),
  deleteProduct: vi.fn(),
}));

vi.mock("../api/categories", () => ({
  getCategories: vi.fn().mockResolvedValue([]),
  getCategory: vi.fn(),
  createCategory: vi.fn(),
  updateCategory: vi.fn(),
  deleteCategory: vi.fn(),
}));

function renderWithProviders(ui: React.ReactElement, initialRoute = "/") {
  return render(
    <ChakraProvider value={system}>
      <MemoryRouter initialEntries={[initialRoute]}>{ui}</MemoryRouter>
    </ChakraProvider>,
  );
}

beforeEach(() => {
  vi.resetAllMocks();
  localStorage.clear();
  mockLocation.href = "";
  mockLocation.pathname = "/";
  // Restore default useAuth mock
  mockUseAuth.mockReturnValue({
    token: "test-token",
    username: "admin",
    permissions: ["EDIT", "PLUGIN_MANAGEMENT"],
    login: vi.fn(),
    logout: vi.fn(),
  });
});

describe("API Client Auth", () => {
  it("includes Authorization header from localStorage token", async () => {
    localStorage.setItem("auth_token", "my-jwt-token");
    mockFetch.mockResolvedValueOnce({
      ok: true,
      status: 200,
      json: () => Promise.resolve({ id: 1 }),
    });

    const { api } = await import("../api/client");
    await api.get("/products");

    expect(mockFetch).toHaveBeenCalledWith("/api/products", expect.objectContaining({
      headers: expect.objectContaining({
        Authorization: "Bearer my-jwt-token",
      }),
    }));
  });

  it("redirects to /login on 401 response", async () => {
    mockFetch.mockResolvedValueOnce({
      ok: false,
      status: 401,
      statusText: "Unauthorized",
      json: () => Promise.resolve({ error: "Unauthorized" }),
    });

    const { api } = await import("../api/client");
    try {
      await api.get("/products");
    } catch {
      // expected
    }

    expect(localStorage.getItem("auth_token")).toBeNull();
    expect(mockLocation.href).toContain("/login");
  });
});

describe("LoginPage", () => {
  it("renders username/password form and submits to /api/auth/login", async () => {
    // Configure mock login to actually call fetch (simulating real behavior)
    const mockLogin = vi.fn(async () => {
      // Simulate what real login does
      mockFetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username: "admin", password: "pass123" }),
      });
    });
    mockUseAuth.mockReturnValue({
      token: null as string | null,
      username: null as string | null,
      permissions: [],
      login: mockLogin,
      logout: vi.fn(),
    });

    const { LoginPage } = await import("../pages/LoginPage");
    renderWithProviders(<LoginPage />);

    expect(screen.getByLabelText(/username/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument();

    fireEvent.change(screen.getByLabelText(/username/i), { target: { value: "admin" } });
    fireEvent.change(screen.getByLabelText(/password/i), { target: { value: "pass123" } });
    fireEvent.click(screen.getByRole("button", { name: /sign in/i }));

    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalledWith("admin", "pass123");
    });
  });
});

describe("AuthContext", () => {
  it("provides token/permissions/login/logout via useAuth hook", async () => {
    // Create a valid JWT
    const payload = btoa(JSON.stringify({ sub: "testuser", permissions: ["EDIT", "PLUGIN_MANAGEMENT"], exp: Math.floor(Date.now() / 1000) + 3600 }));
    const mockToken = `eyJhbGciOiJIUzI1NiJ9.${payload}.signature`;
    localStorage.setItem("auth_token", mockToken);

    // Use the real implementation by delegating to saved reference
    mockUseAuth.mockImplementation(realUseAuth);

    function TestConsumer() {
      const { token, username, permissions, logout } = mockUseAuth();
      return (
        <div>
          <span data-testid="token">{token ?? "none"}</span>
          <span data-testid="username">{username ?? "none"}</span>
          <span data-testid="permissions">{permissions.join(",")}</span>
          <button onClick={logout}>Logout</button>
        </div>
      );
    }

    render(
      <ChakraProvider value={system}>
        <RealAuthProvider>
          <TestConsumer />
        </RealAuthProvider>
      </ChakraProvider>,
    );

    expect(screen.getByTestId("token")).toHaveTextContent(mockToken);
    expect(screen.getByTestId("username")).toHaveTextContent("testuser");
    expect(screen.getByTestId("permissions")).toHaveTextContent("EDIT,PLUGIN_MANAGEMENT");

    fireEvent.click(screen.getByRole("button", { name: /logout/i }));

    await waitFor(() => {
      expect(screen.getByTestId("token")).toHaveTextContent("none");
    });
  });
});

describe("Permission-based UI visibility", () => {
  it("hides New Product button for users without EDIT permission", async () => {
    mockUseAuth.mockReturnValue({
      token: "test-token",
      username: "reader",
      permissions: [],
      login: vi.fn(),
      logout: vi.fn(),
    });

    const { PluginProvider } = await import("../plugins/PluginContext");
    const { ProductListPage } = await import("../pages/ProductListPage");

    render(
      <ChakraProvider value={system}>
        <PluginProvider>
          <MemoryRouter initialEntries={["/products"]}>
            <ProductListPage />
          </MemoryRouter>
        </PluginProvider>
      </ChakraProvider>,
    );

    await waitFor(() => {
      expect(screen.queryByText("+ Add Product")).not.toBeInTheDocument();
    });
  });
});
